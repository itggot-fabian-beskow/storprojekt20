# Projektplan

## 1. Projektbeskrivning (Beskriv vad sidan ska kunna göra)
Sidan ska vara ett sätt för personer att köpa och sälja digitala aktier med "fantasi pengar". Man ska kunna lägga ut aktier för ett visst pris som andra användare sedan kan köpa dem för. Det ska även finnas administratörer som kan skapa pengar och aktier för att hålla marknaden vid liv.

## 2. Vyer (visa bildskisser på dina sidor)
## 3. Databas med ER-diagram (Bild)
## 4. Arkitektur (Beskriv filer och mappar - vad gör/innehåller de?)
```
Stocks
|-app.rb
|
|-db
| |-stonks.db
|
|-public
| |-css
|   |-style.css
|
|-views
  |-user
  | |-read.slim
  | |-show.slim
  |
  |-stock
  | |-create.slim
  | |-delete.slim
  | |-index.slim
  | |-read.slim
  | |-update.slim
  |
  |-index.slim
  |-layout.slim
```
