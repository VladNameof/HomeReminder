"""L1 Polish Store Price & Availability Scraper/Connector (Rossmann, Hebe, Allegro, Ekodrogeria)."""

from __future__ import annotations

import logging
import re
from dataclasses import dataclass
from urllib.parse import quote_plus

import httpx

from app.core.primitives import STORE_SEARCH_TEMPLATES, PolishStore

logger = logging.getLogger(__name__)

PRICE_REGEX = re.compile(r"(\d{1,4}[,.]\d{2})\s*z[łl]", re.IGNORECASE)
TAG_REGEX = re.compile(r"<[^>]+>")

# Common RU -> PL product term translations so Polish stores find Russian product names
RU_TO_PL_DICTIONARY: list[tuple[str, str]] = [
    ("туалетная бумага", "papier toaletowy"),
    ("бумажные полотенца", "ręcznik papierowy"),
    ("бумажные салфетки", "chusteczki papierowe serwetki"),
    ("салфетки для кухни", "ręcznik papierowy kuchenny"),
    ("салфетки", "serwetki chusteczki"),
    ("гель для умывания", "żel oczyszczający do twarzy"),
    ("пенка для умывания", "pianka do mycia twarzy"),
    ("шампунь", "szampon do włosów"),
    ("гель для душа", "żel pod prysznic"),
    ("зубная паста", "pasta do zębów"),
    ("жидкое мыло", "mydło w płynie"),
    ("мыло", "mydło"),
    ("крем для лица", "krem do twarzy"),
    ("сыворотка", "serum do twarzy"),
    ("мицеллярная вода", "płyn micelarny"),
    ("гель для стирки", "żel do prania"),
    ("стиральный порошок", "proszek do prania"),
    ("кондиционер для белья", "płyn do płukania"),
    ("средство для посуды", "płyn do naczyń"),
    ("таблетки для посудомойки", "tabletki do zmywarki"),
]


def normalize_polish_search_query(raw_query: str) -> str:
    """Translates Russian generic product names to Polish keywords so PL stores return exact matches."""
    q = raw_query.strip()
    lower_q = q.lower()
    for ru_term, pl_term in RU_TO_PL_DICTIONARY:
        if ru_term in lower_q:
            lower_q = lower_q.replace(ru_term, pl_term)
    # Remove standalone Cyrillic words if brand/Latin words already exist, or keep translated string
    cleaned = re.sub(r"\s+", " ", lower_q).strip()
    return cleaned if cleaned else q


@dataclass(frozen=True)
class StoreOfferResult:
    store: PolishStore
    product_title: str
    price_pln: float | None
    currency: str
    in_stock: bool
    search_url: str
    note: str


def build_store_search_url(store: PolishStore, query: str) -> str:
    normalized = normalize_polish_search_query(query)
    encoded = quote_plus(normalized)
    template = STORE_SEARCH_TEMPLATES[store]
    return template.format(query=encoded)


def _extract_first_pln_price(html_text: str) -> float | None:
    """Safely extracts the lowest reasonable PLN price from store search HTML."""
    text = TAG_REGEX.sub(" ", html_text)
    matches = PRICE_REGEX.findall(text)
    prices: list[float] = []
    for raw in matches:
        try:
            val = float(raw.replace(",", "."))
            if 2.0 <= val <= 1500.0:
                prices.append(val)
        except ValueError:
            continue
    return min(prices) if prices else None


async def fetch_store_offer(
    client: httpx.AsyncClient,
    store: PolishStore,
    query: str,
    live_scrape: bool = True,
) -> StoreOfferResult:
    search_url = build_store_search_url(store, query)

    if not live_scrape:
        return StoreOfferResult(
            store=store,
            product_title=query,
            price_pln=None,
            currency="PLN",
            in_stock=True,
            search_url=search_url,
            note=f"Прямой поиск «{query}» в {store.value}",
        )

    headers = {
        "User-Agent": (
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
            "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0.0.0 Safari/537.36"
        ),
        "Accept-Language": "pl-PL,pl;q=0.9,en-US;q=0.8",
    }

    try:
        resp = await client.get(search_url, headers=headers, follow_redirects=True)
        if resp.status_code == 200:
            price = _extract_first_pln_price(resp.text)
            if price is not None:
                return StoreOfferResult(
                    store=store,
                    product_title=query,
                    price_pln=round(price, 2),
                    currency="PLN",
                    in_stock=True,
                    search_url=search_url,
                    note=f"Найдено в {store.value} от {price:.2f} zł",
                )
    except Exception as exc:
        logger.debug("Live price check skipped/blocked for %s: %s", store.value, exc)

    return StoreOfferResult(
        store=store,
        product_title=query,
        price_pln=None,
        currency="PLN",
        in_stock=True,
        search_url=search_url,
        note=f"Открыть каталог {store.value}",
    )


async def search_polish_stores(
    query: str,
    stores: list[PolishStore] | None = None,
    live_scrape: bool = True,
) -> list[StoreOfferResult]:
    """Queries Rossmann, Hebe, Allegro, and Ekodrogeria for a product in Poland."""
    target_stores = stores or [
        PolishStore.ROSSMANN,
        PolishStore.HEBE,
        PolishStore.ALLEGRO,
        PolishStore.EKODROGERIA,
    ]
    results: list[StoreOfferResult] = []
    async with httpx.AsyncClient(timeout=4.5) as client:
        for store in target_stores:
            offer = await fetch_store_offer(client, store, query, live_scrape=live_scrape)
            results.append(offer)

    results.sort(key=lambda r: (r.price_pln is None, r.price_pln or 999999.0))
    return results
