# Projektplan

## 1. Projektbeskrivning (Beskriv vad sidan ska kunna göra)
Sidan ska vara ett sätt för personer att köpa och sälja digitala aktier med "fantasi pengar". Man ska kunna lägga ut aktier för ett visst pris som andra användare sedan kan köpa dem för. Det ska även finnas administratörer som kan skapa pengar och aktier för att hålla marknaden vid liv.

## 2. Vyer (visa bildskisser på dina sidor)
![Loginsida](./misc/login.jpg)
![Min sida](./misc/mypage.jpg)
![stocks sidan](./misc/stonks.jpg)
## 3. Databas med ER-diagram (Bild)
![Relationstabell](./misc/relation_table.jpg)
## 4. Arkitektur (Beskriv filer och mappar - vad gör/innehåller de?)
```
Stocks
├── app.rb : Stora delen av applikationen, innehåller alla routes
├── model.rb : Innehåller all databas funktionalitet
│
├── db : Databasen för projektet
│   └── stonks.db
│
├── doc
│   └── Autogenererad dokumentation av yardoc
│
├── Gemfile
│
├── misc : bilder för dokumentationen
│   ├── login.jpg
│   ├── mypage.jpg
│   ├── relation_table.jpg
│   └── stonks.jpg
│
├── projektplan.md
│
├── public : Alla icke slim filer som ska vara tillgängliga för hemsidan
│   └── css
│       └── style.css
│
├── README.md
│
├── sun.png
│
└── views
    ├── error.slim : Error sida
    ├── index.slim : Första sidan, login sida
    ├── layout.slim : Innehåller header och navigation för alla sidorna
    ├── selling : Allt relaterat till försäljningar
    │   └── show.slim
    ├── stock : Allt relaterat till aktier
    │   ├── edit.slim
    │   ├── index.slim
    │   ├── new.slim
    │   └── show.slim
    └── user : Allt relaterat till användare
        ├── read.slim
        └── show.slim
```
