# SCP-215 - Anomalous Sunglasses

## Opis
SCP-215 to anomalne okulary przeciwsłoneczne, które pozwalają użytkownikowi widzieć wrogie jednostki oznaczone czerwonymi kwadratami przez ściany i przeszkody.

## Funkcje
- **Wykrywanie wrogów**: Aktywne okulary pokazują czerwone markery nad wrogimi graczami
- **Przełączanie**: Lewy przycisk myszy (LPM) włącza/wyłącza wykrywanie
- **Cooldown**: Po wyłączeniu wykrywania następuje 10-sekundowy cooldown
- **Ograniczenia zespołowe**: Dostępne tylko dla określonych zespołów (CLASSD, CHAOS, GUARD, NTF, ALPHA1, CI)
- **Wizualne efekty**: Model okularów pojawia się na głowie gracza podczas aktywacji
- **System pękania**: Losowa szansa na pęknięcie okularów przy użyciu

## Zmiany wprowadzone

### Poprawione wykrywanie sojuszników
- CLASSD i CHAOS są teraz traktowani jako sojusznicy
- Czerwone markery nie będą się pojawiać nad członkami sojuszniczych zespołów

### System pękania okularów
- 5% szansy na pęknięcie przy wyłączaniu wykrywania
- 3% szansy na pęknięcie przy włączaniu wykrywania
- Po pęknięciu okulary są usuwane z ekwipunku gracza
- Efekt dźwiękowy pękania szkła

### Przybliżony model okularów
- Zmniejszono offset okularów z 3 do 0.5 jednostek
- Model okularów jest teraz bliżej twarzy postaci

### Usunięte TargetID
- Usunięto hook HUDDrawTargetID
- Brak informacji wyświetlanych przy patrzeniu na SCP-215

### Uproszczony HUD
- Usunięto skomplikowane paski postępu i statusy
- Wyświetla tylko "Put on SCP-215" lub "Take off SCP-215"
- Brak wyświetlania podczas cooldownu

### Poprzednie zmiany
- Usunięto wszystkie wiadomości czatu
- Poprawiono wykrywanie przez ściany (line-of-sight)
- Wyłączono dźwięki przełączania broni
- Dodano 10% szansę spawnu na mapie gm_site19

## Pliki zmodyfikowane
- `init.lua` - system pękania okularów, usunięto wiadomości czatu
- `cl_init.lua` - poprawiono wykrywanie sojuszników, przybliżono model, uproszczono HUD
- `shared.lua` - wyłączono dźwięki przełączania
- `entities/item_scp_215/cl_init.lua` - usunięto TargetID
- `gm_site19.lua` - dodano punkt spawnu dla SCP-215

## Użycie
1. Znajdź SCP-215 na mapie (10% szansa spawnu)
2. Naciśnij E aby podnieść
3. Użyj LPM aby włączyć/wyłączyć wykrywanie wrogów
4. Czerwone markery pojawią się nad wrogimi graczami w zasięgu wzroku
5. Po wyłączeniu czekaj 10 sekund przed ponownym użyciem
6. Uwaga: Okulary mogą pęknąć podczas użycia!