"""L0 Primitives: Core enumerations, units, categories, and Polish store definitions."""

from enum import StrEnum


class ProductCategory(StrEnum):
    COSMETICS = "cosmetics"
    CHEMISTRY = "chemistry"
    PAPER = "paper"


class VolumeUnit(StrEnum):
    ML = "ml"
    G = "g"
    PCS = "pcs"
    WASHES = "washes"
    ROLLS = "rolls"
    SHEETS = "sheets"
    PACKS = "packs"


class PolishStore(StrEnum):
    ROSSMANN = "Rossmann"
    HEBE = "Hebe"
    ALLEGRO = "Allegro"
    EKODROGERIA = "Ekodrogeria"


STORE_SEARCH_TEMPLATES: dict[PolishStore, str] = {
    PolishStore.ROSSMANN: "https://www.rossmann.pl/szukaj?Search={query}",
    PolishStore.HEBE: "https://www.hebe.pl/search?q={query}",
    PolishStore.ALLEGRO: "https://allegro.pl/listing?string={query}",
    PolishStore.EKODROGERIA: "https://ekodrogeria.pl/s?q={query}",
}
