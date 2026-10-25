"""L1 Usage Calculation Engine: Reference Oracle & Gemini AI Adapter."""

from __future__ import annotations

import json
import logging
import math
import re
from dataclasses import dataclass
from datetime import date, timedelta

import httpx

from app.core.primitives import ProductCategory, VolumeUnit

logger = logging.getLogger(__name__)


@dataclass(frozen=True)
class UsageEstimateResult:
    daily_usage_amount: float
    estimated_total_days: int
    expected_end_date: date
    reminder_date: date
    explanation: str
    used_ai: bool = False


# Baseline dose per single application by product keywords and unit
DEFAULT_DOSE_BY_KEYWORD: list[tuple[list[str], float]] = [
    (["туалетн", "papier toaletowy"], 0.25),  # ~0.25 рулона в день на человека
    (["бумажные полотенца", "ręcznik papierowy", "салфетки для кухни", "kuchenn"], 0.15),  # ~1 рулон на неделю
    (["салфетк", "chusteczk", "serwetk"], 4.0),  # ~4 салфетки/листа за раз
    (["сыворотк", "serum", "крем для глаз", "под глаза", "pod oczy"], 0.6),
    (["крем для лиц", "krem do twarzy", "флюид", "spf", "санскрин", "тонер", "тоник", "мицелляр", "micelarny"], 1.5),
    (["гель для умыван", "żel oczyszczający", "пенк", "pianka", "умывалк", "зубн", "паст", "pasta", "жидкое мыло", "мыло", "mydło"], 2.0),
    (["шампун", "szampon", "бальзам", "кондиционер", "odżywka", "гель для душ", "żel pod prysznic", "лосьон для тел", "маск"], 10.0),
    (["порошок", "proszek", "гель для стирк", "żel do prania", "ополаскиватель", "płyn do płukania", "кондиционер для бель"], 50.0),
    (["посуд", "naczyń", "fairy", "средство для мытья", "унитаз", "сантехник", "пол"], 8.0),
]

WORD_NUMBERS: dict[str, int] = {
    "один": 1,
    "одна": 1,
    "раз": 1,
    "вдвоем": 2,
    "вдвоём": 2,
    "двое": 2,
    "два": 2,
    "две": 2,
    "дважды": 2,
    "втроем": 3,
    "втроём": 3,
    "трое": 3,
    "три": 3,
    "трижды": 3,
    "четверо": 4,
    "четыре": 4,
}


def calculate_usage_oracle(
    product_name: str,
    category: ProductCategory,
    total_volume: float,
    unit: VolumeUnit,
    usage_description: str,
    purchase_date: date,
    reminder_days_before: int = 5,
) -> UsageEstimateResult:
    """Deterministic Reference Oracle for calculating daily consumption and depletion date."""
    text = f"{product_name} {usage_description}".lower()

    # 1. Detect explicit daily ml/g/pcs if user wrote e.g. "по 5 мл в день"
    explicit_daily_match = re.search(
        r"по\s*(\d+(?:[.,]\d+)?)\s*(?:мл|ml|г|g|шт|капсул|таблет)\s*(?:в\s*день|ежедневно|в\s*сутки)",
        text,
    )
    if explicit_daily_match:
        daily_usage = float(explicit_daily_match.group(1).replace(",", "."))
        total_days = max(1, math.ceil(total_volume / max(daily_usage, 0.1)))
        end_date = purchase_date + timedelta(days=total_days)
        rem_date = max(purchase_date, end_date - timedelta(days=reminder_days_before))
        return UsageEstimateResult(
            daily_usage_amount=round(daily_usage, 2),
            estimated_total_days=total_days,
            expected_end_date=end_date,
            reminder_date=rem_date,
            explanation=(
                f"Прямой расход ~{daily_usage:.1f} {unit.value}/день "
                f"(хватит на {total_days} дн. до {end_date.strftime('%d.%m.%Y')})."
            ),
            used_ai=False,
        )

    # 2. Detect number of people (users)
    people_count = 1
    if any(w in text for w in ["вдвоем", "вдвоём", "на двоих", "2 человека", "два человека", "с мужем", "с женой", "с девушкой", "с парнем"]):
        people_count = 2
    elif any(w in text for w in ["втроем", "втроём", "на троих", "3 человека", "три человека", "всей семьей", "всей семьёй"]):
        people_count = 3
    elif any(w in text for w in ["4 человека", "четверо"]):
        people_count = 4

    # 3. Detect frequency per day or per week
    times_per_day = 1.0

    # Check "X раз(а) в неделю"
    weekly_match = re.search(r"(\d+)\s*раз[а]?\s*в\s*недел", text)
    if weekly_match:
        times_per_day = float(weekly_match.group(1)) / 7.0
    elif "через день" in text:
        times_per_day = 0.5
    elif "раз в неделю" in text or "по выходным" in text:
        times_per_day = 1.0 / 7.0
    else:
        # Check "X раз(а) в день / сутки"
        daily_match = re.search(r"(\d+)\s*раз[а]?\s*в\s*(?:день|сутки)", text)
        if daily_match:
            times_per_day = float(daily_match.group(1))
        elif "утром и вечером" in text or "дважды в день" in text or "2 раза" in text or "два раза" in text:
            times_per_day = 2.0
        elif "трижды в день" in text or "3 раза" in text or "три раза" in text:
            times_per_day = 3.0

    # 4. Determine single dose amount
    single_dose = 1.0
    explicit_dose_match = re.search(r"по\s*(\d+(?:[.,]\d+)?)\s*(?:мл|ml|г|g|шт|капсул|стир)", text)
    if explicit_dose_match:
        single_dose = float(explicit_dose_match.group(1).replace(",", "."))
    elif unit in (VolumeUnit.PCS, VolumeUnit.WASHES):
        single_dose = 1.0
    else:
        matched_dose = None
        for keywords, dose_val in DEFAULT_DOSE_BY_KEYWORD:
            if any(kw in text for kw in keywords):
                matched_dose = dose_val
                break
        if matched_dose is not None:
            single_dose = matched_dose
        else:
            single_dose = 3.0 if category == ProductCategory.COSMETICS else 15.0

    daily_usage = max(0.1, single_dose * times_per_day * people_count)
    total_days = max(1, math.ceil(total_volume / daily_usage))
    end_date = purchase_date + timedelta(days=total_days)
    rem_date = max(purchase_date, end_date - timedelta(days=reminder_days_before))

    explanation = (
        f"Расчёт: ~{single_dose:g} {unit.value} за раз × {times_per_day:.2g} раз/день"
        + (f" × {people_count} чел." if people_count > 1 else "")
        + f" = {daily_usage:.1f} {unit.value}/день. Хватит на {total_days} дн."
    )

    return UsageEstimateResult(
        daily_usage_amount=round(daily_usage, 2),
        estimated_total_days=total_days,
        expected_end_date=end_date,
        reminder_date=rem_date,
        explanation=explanation,
        used_ai=False,
    )


async def estimate_usage_smart(
    product_name: str,
    category: ProductCategory,
    total_volume: float,
    unit: VolumeUnit,
    usage_description: str,
    purchase_date: date,
    reminder_days_before: int = 5,
    gemini_api_key: str = "",
    gemini_model: str = "gemini-2.5-flash",
) -> UsageEstimateResult:
    """Calculates usage via Gemini Flash if API key is provided, with deterministic Oracle fallback."""
    oracle_result = calculate_usage_oracle(
        product_name=product_name,
        category=category,
        total_volume=total_volume,
        unit=unit,
        usage_description=usage_description,
        purchase_date=purchase_date,
        reminder_days_before=reminder_days_before,
    )

    if not gemini_api_key.strip():
        return oracle_result

    prompt = (
        "Ты эксперт по расчёту расхода косметики и бытовой химии.\n"
        "Проанализируй данные о покупке и верни ТОЛЬКО валидный JSON без markdown-обертки:\n"
        '{"daily_usage_amount": float, "estimated_total_days": int, "explanation": "краткое пояснение на русском"}\n\n'
        f"Товар: {product_name}\n"
        f"Категория: {category.value}\n"
        f"Объём/количество: {total_volume} {unit.value}\n"
        f"Описание использования: {usage_description}\n"
    )

    url = f"https://generativelanguage.googleapis.com/v1beta/models/{gemini_model}:generateContent"
    try:
        async with httpx.AsyncClient(timeout=8.0) as client:
            resp = await client.post(
                url,
                params={"key": gemini_api_key},
                json={
                    "contents": [{"parts": [{"text": prompt}]}],
                    "generationConfig": {"responseMimeType": "application/json", "temperature": 0.1},
                },
            )
            resp.raise_for_status()
            data = resp.json()
            raw_text = data["candidates"][0]["content"]["parts"][0]["text"]
            parsed = json.loads(raw_text)
            daily = max(0.05, float(parsed["daily_usage_amount"]))
            days = max(1, int(parsed.get("estimated_total_days") or math.ceil(total_volume / daily)))
            end_date = purchase_date + timedelta(days=days)
            rem_date = max(purchase_date, end_date - timedelta(days=reminder_days_before))
            return UsageEstimateResult(
                daily_usage_amount=round(daily, 2),
                estimated_total_days=days,
                expected_end_date=end_date,
                reminder_date=rem_date,
                explanation=str(parsed.get("explanation") or oracle_result.explanation),
                used_ai=True,
            )
    except Exception as exc:
        logger.warning("Gemini API fallback to deterministic UsageOracle: %s", exc)
        return oracle_result
