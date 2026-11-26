# Eziach bauen

<!--
The assembly guide's text and pictures. guide.py turns it into build/assembly/guide.html
(make -C assembly). Each ```view block is a picture rendered from the built models
(guide.py's docstring lists its keys); the text is written here, in German, from the specs:
../../switch_hall/spec.md §2 (the keys), ../../discant/spec.md §3 and §7, ../../strain_gauge/spec.md
§7, ../../bass/spec.md §3 and §4, ../spec.md (Latches, Overload stops, Contacts, Wiring),
../../firmware/spec.md §6. When a spec's order or a part changes, change the step here;
the pictures follow the models by themselves.
-->

## Überblick

Das Instrument besteht aus zwei Hälften. Der **Diskant** (46 Tasten, rechte Hand) trägt die beiden Messplatten; der **Bass** (2 × 9 Tasten, linke Hand) trägt Hauptplatine, Akku, Klinke und USB-C und wird zum Spielen auf die Messplatten geschoben. Strom und I²C gehen über sechs Federkontakte, sobald die Hälften zusammenstecken.

```view
frame: assembly
show: bass/case bass/cover bass/keys_static bass/strap bass/lever d_housing d_cover d_boards keys_discant d_cables
cam: 205 28 1.15
caption: Beide Hälften zum Spielen zusammengesteckt, von hinten gesehen
```

Die Reihenfolge: zuerst alle 64 Tasten (sie brauchen 12 h zum Aushärten), dann Diskant und Bass unabhängig voneinander, zuletzt Firmware, Zusammenstecken und Einstellen.

### Drucken

Alle Teile in PETG. Die Lage auf dem Druckbett ist für die Passungen gewählt:

- **Diskant-Gehäuse** stehend auf seiner Vorderkante, die Halter nach oben, diagonal aufs Bett; breiter Rand (8–10 mm) und ein paar Stützrippen im Slicer gegen Wackeln oben.
- **Diskant-Deckel** flach, Oberseite nach unten, diagonal; Stützen höchstens unter den Enden der Daumenleiste.
- **Bass-Gehäuse** stehend auf der Handfläche (die inneren Halter stehen dann auf ihren Brücken).
- **Bass-Deckel**, **Rückdeckel** (auf seiner Innenseite) und **Spannhebel** (kopfüber auf seiner flachen Oberseite).
- 64 **Kappen** und 64 **Kragen** für die Tasten.

Teile: alles Gekaufte steht in `BOM.md`; Platinen: Hauptplatine, Hall-Platine Diskant, Hall-Platine Bass, Kontakt-Nutzen

### Platinen vorbereiten

Die vier Platinen kommen bestückt (JLCPCB). Den Kontakt-Nutzen an den Stegen ausbrechen: die **Stiftplatine** (6 Federstifte) gehört in den Bass, die **Padplatine** (6 Goldpads) auf den Diskant. Die Stege sauber abfeilen; die Padplatine wird später kantenbündig auf ihren Sockel geklebt.

## Tasten

64 gleich aufgebaute Tasten: 46 für den Diskant, 18 für den Bass (die hintere Bassreihe mit 24 mm langer Stange). Jede Taste läuft mit einem Stahlstift in einer Bronzebuchse im Deckel; unten am Stift sitzt der Magnet, den der Hall-Sensor auf der Platinenunterseite durch die Platine hindurch misst.

### Die Teile einer Taste

```view
frame: key
show: cap@0,0,26 oring@0,0,20 spring@0,0,10 rod@0,0,9 tube bushing@0,0,-10 stop@0,0,-16 collar@0,0,-22 magnet@0,0,-28
cam: 25 12 1.05
caption: Von oben: Kappe, O-Ring, Feder, Stift, Rohr im Deckel, Bronzebuchse, Anschlagscheibe, Kragen, Magnet
```

Teile: Passstift ⌀3 × 14 (× 24); Sinterbronzebuchse 3 × 5 × 4; Druckfeder UY8-25; O-Ring 4 × 1,5; Anschlagscheibe ⌀4,5 / ⌀2,5 oder O-Ring 2,5 × 1; Magnet ⌀3 × 1 N52; Kappe und Kragen (Druck); Zweikomponenten-Epoxid, langsam

### Stift vorbereiten, Kappe kleben

1. Beide Enden des Stifts auf etwa 3 mm mit 240er Papier anrauen und mit Isopropanol entfetten. Die Mitte, die in der Buchse läuft, bleibt glatt und sauber.
2. Einen kleinen Tropfen Epoxid mit einem Zahnstocher in die Bohrung der Kappe (nicht auf den Stift), den Stift gerade bis zum Grund einpressen, Austritt abwischen.

```view
frame: key
new: cap@0,0,6 rod
cam: 25 12
caption: Der Stift wird 2,7 mm tief in die Kappe geklebt
```

> Kein Sekundenkleber: Er kriecht am Stift entlang in Buchse und Anschlagscheibe und setzt die Taste fest. Eine Mischung langsames Epoxid reicht für einen ganzen Deckel.

### Magnet in den Kragen

Etwas langsames Epoxid in die Tasche des Kragens, den Magneten von unten einsetzen und bis an den Steg schieben, Austritt an seiner Unterseite abwischen. Die Tasche ist etwas weiter als der Magnet (⌀3,1 gemessen); er sitzt nur durch den Kleber. **Alle Tasten mit demselben Pol nach unten**: gegen einen markierten Magneten prüfen, bevor der Kleber anzieht.

```view
frame: key
new: collar magnet@0,0,-8
cam: 25 -20
caption: Der Magnet sitzt unter einem 0,5-mm-Steg im Kragen
```

### Buchse ins Rohr

Den Deckel umdrehen. Jede Bronzebuchse von unten in ihr Rohr schieben und bis an den Rand oben einpressen. Sie hält durch die Form, ohne Kleber.

```view
frame: key
show: tube
new: bushing@0,0,-10
cam: 25 -15
focus: tube bushing@0,0,-10
caption: Die Buchse von unten bis an den 0,8-mm-Rand
```

### Feder, O-Ring und Stift

Den Deckel richtig herum hinlegen. Die Feder über das Rohr auf ihren Sitz, den O-Ring in die Senkung unter der Kappe, dann den Stift mit der Kappe von oben durch die Buchse stecken.

```view
frame: key
show: tube bushing
new: spring@0,0,8 oring@0,0,22 cap@0,0,22 rod@0,0,22
cam: 25 12
caption: Feder auf den Sitz, Stift mit Kappe und O-Ring von oben
```

### Anschlagscheibe und Kragen

1. Den Deckel auf die Kappen umdrehen: Die Federn halten alle Tasten in Ruhelage.
2. Das untere Stiftende mit Isopropanol abwischen (es kommt gerade aus der geölten Buchse) und trocknen lassen.
3. Die Anschlagscheibe über das Stiftende schieben (sie hält von selbst).
4. Etwas Epoxid nur in die Bohrung des Kragens, Kragen aufsetzen, bis der Stift auf dem Magnetsteg sitzt. Die Feder zieht den Kragen gegen die Buchse, eine Vorrichtung braucht es nicht.
5. Den Deckel 12 h auf den Kappen liegen lassen.

```view
frame: key
show: cap oring spring rod tube bushing
new: stop@0,0,-8 collar@0,0,-16 magnet@0,0,-16
cam: 25 -8
focus: cap rod tube stop@0,0,-8 collar@0,0,-16
caption: Von unten: Anschlagscheibe, dann der Kragen mit dem Magneten
```

> Kein Kleber an Scheibe oder Buchse. Zum Auseinandernehmen einer fertigen Taste (Feder oder Buchse tauschen): `switch_hall/spec.md`, „Taking a key apart“.

## Verkabelung

Alle Verbindungen sind lose, einzelne Litzen, leicht verdrillt und gebündelt; gelötet wird an Pads, nur am Stecker J1 der Bass-Tastenplatine steckt ein JST-SH-Stecker. Die beiden Hälften verbindet nichts als die sechs Federkontakte. Längen und Belegungen auf dieser Seite werden beim Bauen aus den Modellen und Platinenquellen gelesen.

```view
frame: bass
ghost: case
show: elec boards connectors contact_pins
new: wires_*
cam: 180 12
focus: case
caption: Alle Drähte im Bass, von hinten bei offenem Rückdeckel; Bilder mit dicker gezeichneten Drähten bei den einzelnen Läufen
```

### Läufe und Zuschnitt

Zuschnitt = Länge im Modell + 20 mm je Ende zum Abisolieren und als Zugentlastung, auf 10 mm aufgerundet; bei #4 kommen 30 mm dazu, weil die Stiftplatine vor dem Block angelötet wird.

| # | Hälfte | von → nach | Drähte | Modell | Zuschnitt |
|---|---|---|---|---|---|
| 2 | Diskant | Padplatine → Hall-Platine J1 | 5: 3,3 V, GND, SDA, SCL, INT | {{scad:discant/gauge_link.scad:path_len(contact_pts())}} mm | {{cut:discant/gauge_link.scad:path_len(contact_pts())}} mm |
| 3 | Diskant | Messplatten → J2 / J3 | 2 × 3: rot, gelb, schwarz | {{scad:discant/gauge_link.scad:path_len(lead_pts(-1))}} mm | {{cut:discant/gauge_link.scad:path_len(lead_pts(-1))}} mm je |
| 4 | Bass | Stiftplatine → Hauptplatine P1–P6 | 6: 3,3 V, GND, SDA, SCL, INT, DET | {{scad:bass/elec.scad:path_len(pins_pts()) + path_len(main_leg_pts())}} mm | {{cut:bass/elec.scad:path_len(pins_pts()) + path_len(main_leg_pts()):30}} mm |
| 5 | Bass | Bass-Tastenplatine J1 → P7–P11 | 5: 3,3 V, GND, SDA, SCL, INT | {{scad:bass/elec.scad:path_len(key_pts())}} mm | {{cut:bass/elec.scad:path_len(key_pts())}} mm |
| 6 | Bass | Akku-Stecker → P12–P15 | 4: −, NTC-Rückleitung, TS, + | {{scad:bass/elec.scad:path_len(tail_pts())}} mm | {{cut:bass/elec.scad:path_len(tail_pts())}} mm |
| 7 | Bass | Klinke → P19–P21 | 3: Spitze, Ring, Hülse | {{scad:bass/elec.scad:max([for (k = [0 : 2]) path_len(jack_pts(k))])}} mm | {{cut:bass/elec.scad:max([for (k = [0 : 2]) path_len(jack_pts(k))]) + jack_slack}} mm |

Teile: Litze AWG 30, 7 × 0,1, PTFE dünnwandig (⌀ ≤ 0,55), je 2 m rot, schwarz, blau, gelb, weiß, 1 m grün; AWG 26 PTFE je 0,3 m rot und schwarz (Akku); JST-SH-Kabel 5-polig, vorgecrimpt; JST-PH-2-Paar (Akku) und JST-SH-2-Paar (NTC); Schrumpfschlauch ⌀1,5 und ⌀3

### Farben und Löten

Die Farbe folgt dem Signal, auf beiden Hälften gleich: **3,3 V rot, GND schwarz, SDA blau, SCL gelb, INT grün, DET weiß**; Akku + rot, − schwarz, NTC orange (TS) und braun (Rückleitung); Klinke Spitze weiß, Ring rot, Hülse schwarz; die Messplatten wie gekauft (rot, gelb, schwarz).

1. Etwa 2 mm abisolieren, verdrillen, verzinnen; PTFE verträgt den Lötkolben, schmilzt also nicht zurück.
2. Die Drähte eines Laufs leicht miteinander verdrillen. Silikonlitze derselben Stärke ist zu dick für die Kanäle.
3. Wo Drähte durch Platinenlöcher gehen (Diskant J1–J3, Hauptplatine P1–P15), von der Bauteilseite her einstecken, oben löten und unten bündig abschneiden.

### Belegung der Hauptplatine

{{table:main_pads}}

```view
frame: bass
ghost: case
show: elec
new: bass/elec.scad:contact_strands() bass/elec.scad:key_strands() bass/elec.scad:bat_strands() bass/elec.scad:jack_strands()
cam: 180 20 1.0
focus: elec
wire: 1.6
caption: Die Drähte an den Pads der Hauptplatine: hinten P1–P15 in zwei Reihen, rechts oben die Klinke auf P19–P21
```

> P4, P8, P12 und P13 hängen an der Massefläche und brauchen eine heißere Lötspitze.

### Belegung der Kontaktplatinen

Die Stiftplatine (Bass) von vorn, also so, wie man vom Diskant aus auf die Stifte schaut; die Padplatine des Diskants trägt dieselbe Belegung gespiegelt. Auf der Rückseite liegen die Drahtpads im selben Raster, beschriftet.

{{table:contact_grid}}

Auf der Padplatine ist DET mit GND verbunden; dort gehen nur fünf Drähte ab. Die Hall-Platine des Diskants hat an J1 die Reihenfolge INT, 3,3 V, SDA, SCL, GND (Pin 1 bis 5), die des Bass ebenso am JST-SH-Stecker.

### #2 Diskant: Kontakte zur Hall-Platine

Von den Pads auf der Rückseite der Padplatine zieht jeder Draht erst gerade nach hinten, dann gehen alle fünf durch die ⌀2,2-Bohrung im Sockel nach unten in die Nut, durch den mittleren Kanal unter die Platine und von unten durch J1.

```view
frame: discant
ghost: housing
show: discant/gauge_link.scad:contact_board()
new: discant/gauge_link.scad:contact_wires()
cam: 215 30 1.0
wire: 2
caption: Die fünf Drähte vom Sockel durch Bohrung und Kanal zu J1
```

### #3 Diskant: Messplatten zu J2 und J3

Die drei Drähte jeder Platte verlassen sie in einer Reihe an der Kante, liegen flach nebeneinander in der Nut und drehen sich auf dem Weg nach unten als Band um etwa 70°, sodass sie im schrägen Kanal quer zu ihrem Weg liegen. Unter der Padreihe gehen sie von unten durch J2 (linke Platte) bzw. J3 (rechte Platte): rot an AVDD (E+), gelb an die Mitte, schwarz an GND, wie auf der Platine beschriftet.

```view
frame: discant
ghost: housing
show: discant/gauge_link.scad:gauge()
new: discant/gauge_link.scad:lead_wires()
cam: 200 50 0.8
focus: discant/gauge_link.scad:lead_wires()
wire: 2
caption: Beide Messplatten mit ihren drei Drähten in Nut und Kanälen
```

### #4 Bass: Kontakte zur Hauptplatine

Das Bündel kommt aus dem Hohlraum hinter der Stiftplatine durch die ⌀2,6-Bohrung der Rückwand, biegt am Fenster des Fußes um die Ecke in den Schlitz darunter und läuft unten an der Rückseite entlang bis zur Hauptplatine. Dort fächert es nach vorn auf P1–P6 auf.

```view
frame: bass
ghost: case
show: contact_pins elec
new: bass/elec.scad:contact_strands()
cam: 190 10 1.0
wire: 2
caption: Lauf #4 von der Stiftplatine (Mitte unten) nach rechts zur Hauptplatine
```

### #5 Bass: Tastenbus

Vom Stecker J1 der Bass-Tastenplatine durch ihren Schacht in den Tunnel im Deck, über den Block des linken Riemenstegs, links neben dem Akku hinunter und unten vor #4 entlang zu P7–P11. Die Spleißstelle zum Stecker liegt im Tunnel des Decks.

```view
frame: bass
ghost: case
show: boards connectors elec
new: bass/elec.scad:key_strands()
cam: 185 15 1.0
wire: 2
caption: Lauf #5 vom Stecker oben links hinunter und unten entlang
```

### #6 Bass: Akku

Die Akkuleitungen und die des NTC gehen durch die Kerbe der Rippe rechts neben dem Akku zu ihren Steckern im Feld über der Hauptplatine. Von dort läuft der Schwanz durch die Kerbe der Rippe über dem Netzteilbereich, die Spalte links neben der Hauptplatine hinunter und unten vorn entlang zu P12–P15. + und − in AWG 26.

```view
frame: bass
ghost: case
show: battery elec
new: bass/elec.scad:bat_strands()
cam: 185 15 1.0
wire: 2
caption: Akkuleitungen, Stecker und der Schwanz zur Hauptplatine
```

### #7 Bass: Klinke

Drei kurze Drähte von den SMD-Pads P19–P21 hinauf zu den Lötfahnen: Spitze weiß, Ring rot, Hülse schwarz. Die Pad-Seite wird auf dem Tisch gelötet, die Lötfahnen erst, wenn die Klinke eingeschraubt ist. Die Klinke hat keine Verdrehsicherung; wie ihre Fahnen am Ende stehen, ergibt sich beim Einschrauben. Darum sind die Drähte {{scad:bass/elec.scad:jack_slack}} mm länger zugeschnitten und werden an der Klinke gekürzt. Spitze und Ring sind zwei flache Fahnen dicht neben der Achse, die Hülse eine längere Fahne außen; das Bild zeigt eine der möglichen Lagen.

```view
frame: bass
ghost: case elec bass/elec.scad:jack()
new: bass/elec.scad:jack_strands()
cam: 200 30 0.7
focus: bass/elec.scad:jack() bass/elec.scad:jack_strands()
wire: 1.6
caption: Die Klinke über der Hauptplatine, die Drähte zu P19–P21
```

## Diskant

### Gewindeeinsätze der Überlaststopps

In die beiden Zungen außen an den Messplatten-Haltern je einen M3-Gewindeeinsatz (⌀4,0, 4 lang) von unten mit dem Lötkolben einsetzen. Die Madenschraube M3 × 6 (S2) dreht später von unten hinein; sie wird erst im letzten Kapitel eingestellt.

```view
frame: discant
show: housing
new: discant/gauge_link.scad:gauge_stop_tongues()
cam: 165 -20 0.9
caption: Die beiden Zungen (orange) an den äußeren Haltern, von unten
```

### Padplatine: Drähte und Kleben

1. Fünf Drähte (AWG 30 PTFE, je {{cut:discant/gauge_link.scad:path_len(contact_pts())}} mm) an die Pads auf der Rückseite der Padplatine löten: 3,3 V rot, GND schwarz, SDA blau, SCL gelb, INT grün. DET ist auf der Platine mit GND verbunden.
2. Die Drähte durch die Bohrung im Sockel nach unten in die Nut und weiter durch den mittleren Kanal unter die Platinenauflage führen.
3. Nur einen dünnen Film langsames Epoxid auf den Sockel streichen, die Platine kantenbündig auflegen und satt andrücken, bis am Rand etwas Kleber austritt; abwischen und angedrückt halten, bis es fest ist. Die Fuge muss so dünn bleiben (unter 0,1 mm), weil sie die Padfläche den Federstiften des Bass entgegenhebt: Bei dicker Fuge gehen die Stifte auf Block, und ein Teil der Kraft läuft an den Messplatten vorbei. Kontrolle mit dem Tiefenmaß des Messschiebers: Die Spitzen der äußeren Halter stehen 4,6 mm vor der Padfläche, nach dem Kleben sollen es noch mindestens 4,5 mm sein.

```view
frame: discant
show: housing
new: discant/gauge_link.scad:contact_board() discant/gauge_link.scad:contact_wires()
cam: 200 35 0.6
caption: Die Padplatine auf ihrem Sockel zwischen den Haltern, die fünf Drähte durch Bohrung und Kanal
```

### Messplatten einsetzen

Die Reihenfolge ist durch die Geometrie vorgegeben:

1. Jede Messplatte von hinten in ihren äußeren Halter schieben, die Anschlussdrähte voraus, bis ihre Kante am Polster anliegt.
2. Je zwei Passstifte ⌀1,5 × 10 quer durch die Backen des Halters: Sie halten die Platte.
3. Die drei Drähte jeder Platte (rot, gelb, schwarz, wie gekauft) flach nebeneinander in die Nut legen. Auf dem Weg nach unten drehen sie sich als Band um etwa 70°, dann laufen sie durch den schrägen Kanal unter die Padreihe J2 bzw. J3. Bei Bedarf auf {{cut:discant/gauge_link.scad:path_len(lead_pts(-1))}} mm verlängern.

```view
frame: discant
show: housing discant/gauge_link.scad:contact_board()
new: discant/gauge_link.scad:gauge() discant/gauge_link.scad:lead_wires()
cam: 200 40 1.3
focus: discant/gauge_link.scad:gauge()
caption: Beide Messplatten in ihren Haltern, die Drähte in Nut und Kanälen
```

### Hall-Platine einlegen und löten

1. Die Hall-Platine in die Wanne legen. Dabei die drei Drahtbündel von unten durch ihre Löcher führen: die fünf Kontaktdrähte durch J1, die Messdrähte durch J2 (links) und J3 (rechts).
2. Oben verlöten und kurz abschneiden. Der Deckel hat über den Lötstellen eine 1,3 mm tiefe Aussparung.

```view
frame: discant
show: housing gauge_link wires_*
new: board board_parts
cam: 195 50
caption: Die Platine in der Wanne; die Drähte kommen unter der Hinterkante hoch
```

### Deckel mit den Tasten aufschrauben

Den Deckel mit allen 46 Tasten auf die Platine setzen und mit **27 Senkschrauben M2 × 6 aus Messing** durch Deckel und Platine in die Dome der Wanne schrauben. Mit zwei Fingern am kleinen Schraubendreher anziehen und aufhören, sobald der Kopf bündig ist: Das Gewinde im Kunststoff reißt lange vor dem Messing. Beim erneuten Öffnen jede Schraube erst zurückdrehen, bis sie in ihr Gewinde fällt.

```view
frame: discant
show: housing board gauge_link
new: cover keys
cam: 195 45
caption: Deckel mit 46 Tasten
```

Zum Schluss den Schultergurt mit seinen Karabinern in die beiden Ösen unten an den vorderen Ecken hängen.

## Bass

### Gehäuse vorbereiten

1. Das Loch für die Klinke (⌀5,3 gedruckt) mit **M6 × 0,75** (Feingewinde) nachschneiden.
2. In den Boden jedes Blocks neben den inneren Haltern einen M3-Gewindeeinsatz von unten einsetzen; dort sitzt später die Madenschraube M3 × 4 (S1).
3. In die beiden Druckschuhe der Klemmung je eine Madenschraube **M2 × 3** eindrehen (Gewinde M2 vorher schneiden). Sie stellen später die Klemmkraft ein.

```view
frame: bass
show: case
cam: 160 -15 1.0
caption: Das Bass-Gehäuse von hinten unten; hinten offen, der Rückdeckel kommt zuletzt
```

### Tastendeck

Die Hall-Platine des Bass in das Deck legen, den Bass-Deckel mit seinen 18 Tasten aufsetzen und mit **12 Senkschrauben M2 × 6 (Messing)** verschrauben, wie beim Diskant. Der Stecker J1 der Platine hängt nach unten in den Kasten.

```view
frame: bass
show: case
new: boards connectors cover keys_static
cam: 200 35
focus: case
caption: Platine und Deckel mit den 18 Tasten auf dem Deck
```

### Hauptplatine auf dem Tisch verdrahten

Im Kasten wird nichts gelötet: Die Drahtpads der Hauptplatine liegen später hinter der Leiste unten, wo kein Lötkolben hinkommt. Deshalb alle Drähte vorher an die lose Platine löten (Belegung: Kapitel Verkabelung):

- **#4 Kontakte**, 6 Drähte zu je {{cut:bass/elec.scad:path_len(pins_pts()) + path_len(main_leg_pts()):30}} mm, an P1–P6: INT grün, 3,3 V rot, SCL gelb, GND schwarz, DET weiß, SDA blau.
- **#5 Tastenbus**, 5 Drähte zu je {{cut:bass/elec.scad:path_len(key_pts())}} mm, an P7–P11: 3,3 V, GND, INT, SCL, SDA. Ans andere Ende kommt der JST-SH-Stecker (vorgecrimptes Kabel, kurz hinter dem Stecker an den PTFE-Draht gespleißt, Schrumpfschlauch).
- **#6 Akku-Schwanz**, {{cut:bass/elec.scad:path_len(tail_pts())}} mm, an P12–P15 (− schwarz, NTC-Rückleitung braun, TS orange, + rot; AWG 26 für + und −), am Ende die Gegenstecker zum JST-PH des Akkus und zum JST-SH des NTC.
- **#7 Klinke**, 3 × {{cut:bass/elec.scad:max([for (k = [0 : 2]) path_len(jack_pts(k))]) + jack_slack}} mm, auf die SMD-Pads P19–P21: Spitze weiß, Ring rot, Hülse schwarz. Die Drähte bleiben bewusst lang; gekürzt wird erst an der Klinke.

Die freien Enden von #4 und #5 jeweils mit einem Stück Schrumpfschlauch zu einer Spitze bündeln.

```view
frame: bass
ghost: case
show: battery
new: elec wires_*
cam: 180 10 0.6
focus: elec
caption: Die Hauptplatine unten rechts und die Drähte, wie sie im Kasten liegen werden
```

### Hauptplatine einbauen

Rückdeckel und Akku sind noch draußen. Die Platine 2 mm links von ihrem Platz einsetzen und nach rechts in die USB-Öffnung schieben. Mit **3 Linsenschrauben M2 × 3** an die Vorderwand schrauben; die unterste erreicht man durch das ⌀4-Loch in der Leiste. Den Akku-Schwanz unten vorn entlang, links an der Platine hoch und durch die Kerbe der Rippe über dem Netzteilbereich ins Feld darüber legen.

```view
frame: bass
show: case
new: elec bass/elec.scad:bat_strands()
cam: 180 15 0.7
focus: elec
caption: Die Hauptplatine an ihrem Platz, der Akku-Schwanz nach oben ins Feld über ihr
```

### Klinke einsetzen

Von hinten, knapp 4 mm vor der Wand und 2,4–3 mm höher als ihr Platz, die Klinke in die Mulde senken; die drei Drähte dabei zur Seite biegen. Nach rechts schieben und knapp 5 Umdrehungen in das Gewinde der Seitenwand schrauben, bis der Flansch anliegt; ein Tropfen Schraubensicherung.

Dann die Drähte an die Fahnen löten, wie diese gerade stehen: Spitze (weiß) und Ring (rot) an die beiden flachen Fahnen dicht an der Achse, Hülse (schwarz) an die längere äußere Fahne. Von den Fahnen her gesehen, mit der Hülsenfahne oben, liegt die Spitze rechts und der Ring links; im Zweifel zeigt es ein Durchgangsprüfer mit eingestecktem Stecker. Jeden Draht in einem lockeren Bogen bis an sein Loch führen, dort kürzen, durchstecken, umbiegen und löten. Der Kolben kommt von hinten an alle Fahnen heran, auch wenn die Hülsenfahne zur Platine zeigt: Sie ragt 2,8 mm über die flachen Fahnen hinaus, ihr Loch liegt dort frei. Die Drähte dürfen nicht mehr als 4 mm von der Achse abstehen, sonst stößt die Rippe des Rückdeckels an.

```view
frame: bass
show: case elec
new: bass/elec.scad:jack() bass/elec.scad:jack_strands()
cam: 250 45 1.0
focus: bass/elec.scad:jack()
wire: 1.6
caption: Die Klinke in ihrer Wiege, von hinten bei abgenommenem Rückdeckel; die Drähte von den Pads zu den Fahnen (eine der möglichen Lagen)
```

### Kontaktdrähte und Stiftplatine

1. Das Bündel #4 unten hinten nach links legen, durch den Schlitz unter dem Fuß bis zu seinem Fenster, dort um die Ecke in die Bohrung und hinaus in den Hohlraum des Halteblocks.
2. Etwa 30 mm vor dem Block herausziehen und an die Rückseite der Stiftplatine löten (Belegung wie auf der Platine aufgedruckt).
3. Die Platine von vorn in ihre Tasche drücken, die 30 mm zurück in den Kasten ziehen. Ein Tropfen neutral vernetzendes Silikon an zwei Ecken hält sie, solange die Hälften getrennt sind.

```view
frame: bass
show: case elec
new: contact_pins bass/elec.scad:contact_strands()
cam: 200 20 0.9
focus: contact_pins bass/elec.scad:contact_strands()
caption: Bündel #4 von der Hauptplatine durch Fuß und Bohrung zur Stiftplatine
```

### Tastenbus

Das Bündel #5 vor #4 unten entlang, durch den Schlitz, links neben dem Akkufach hoch und weiter bis zum Stecker J1 der Hall-Platine; einstecken.

```view
frame: bass
show: case elec contact_pins bass/elec.scad:contact_strands()
new: bass/elec.scad:key_strands()
cam: 180 15
focus: case
caption: Bündel #5 von der Hauptplatine hinauf zu J1
```

Die Reserven von #4 (etwa 50 mm) und #5 (etwa 20 mm) als stehende Schlaufen in die freie Spalte zwischen der dicken Basis der rechten Außenrippe und der Kante der Hauptplatine legen.

### Handriemen

Bei offenem Rückdeckel den Lederriemen (40 mm) an jedem Ende durch den inneren Schlitz hinein, um den Steg im Kasten und durch den äußeren Schlitz wieder hinaus fädeln, umschlagen und schnallen.

```view
frame: bass
ghost: case
new: strap
cam: 0 15
focus: case
caption: Der Riemen über dem Handrücken, jedes Ende durch zwei Schlitze
```

### Akku

Den Akku mit der Schutzplatine nach rechts einlegen. Seine Leitungen und die des NTC in die Kerbe oben in der Rippe daneben legen und im Feld über der Hauptplatine einstecken; was von den Akkuleitungen übrig ist, dort in eine Schlaufe legen.

```view
frame: bass
show: case elec wires_*
new: battery
cam: 180 15
focus: case
caption: Der Akku zwischen Vorderwand und Rückdeckel, Stecker rechts oben
```

> Der Akku kommt später ohne Löten wieder heraus: Deckel ab, beide Stecker ziehen, Leitungen aus der Kerbe heben. Ein 2-Draht-Akku bekommt den NTC mit Kaptonband auf die obere Kante, 3–5 mm vom Ende ohne Schutzplatine (`bass/spec.md`, Battery).

### Rückdeckel

Den Rückdeckel von links (−x) in seiner Ebene einschieben, bis er rechts an der Wand der Klinke anstößt; unten gleitet er auf die 45°-Rampe. Oben mit **3 Senkschrauben M2 × 6** in die Pfeiler schrauben.

```view
frame: bass
show: case battery elec wires_* strap
new: back_cover@-120,0,0 cover_screws
cam: 165 20
focus: case
caption: Der Rückdeckel wird von links eingeschoben
```

### Spannhebel

Den Spannhebel zwischen die vier Laschen der inneren Halter setzen und die Achse (Silberstahl ⌀2 × 73) durch Laschen und Hebel schieben. Geschlossen liegt der Hebel flach auf den Haltern, der Quersteg zwischen ihnen.

```view
frame: bass
show: case back_cover contact_pins
new: lever latch_rod
cam: 200 35 0.9
focus: lever
caption: Der Hebel mit seinen zwei Nocken über den inneren Haltern
```

## Inbetriebnahme

### Firmware

Beim ersten Mal über UART0 (die TX/RX-Testpads der Hauptplatine und ein USB-Seriell-Adapter) Programm und Soundfont flashen; danach geht alles über das USB-C-Kabel:

```view
frame: bass
show: case back_cover cover keys_static elec
cam: 100 10 0.8
focus: elec
caption: USB-C, Ladeanzeige und Klinke in der rechten Seitenwand
```

1. `idf.py build`, dann `idf.py -p /dev/ttyUSB0 flash monitor` (das erste Mal).
2. Später: in der Konsole `download`, dann `idf.py -p /dev/ttyACM0 flash`.
3. Die Konsole (`screen /dev/ttyACM0`) zeigt mit `status` Platinen, Messzellen und DAC.

### Zusammenstecken

Den Bass mit seinen inneren Haltern auf die beiden Messplatten schieben, bis sie anliegen, und den Spannhebel flach herunterdrücken. Dabei schalten die Federkontakte das System ein (DET). Zum Abnehmen den Quersteg mit einem Finger 90° hochklappen und den Bass abziehen.

```view
frame: assembly
show: bass/case bass/back_cover bass/contact_pins d_housing d_boards
new: bass/lever d_cables
cam: 200 40 0.8
focus: bass/lever
caption: Die Messplatten (orange) in den inneren Haltern, darüber der Spannhebel
```

Die Klemmkraft stellen die beiden Madenschrauben M2 × 3 in den Druckschuhen ein: etwa 45 N je Halter, der Hebel soll sich gerade fest umlegen lassen.

### Überlaststopps einstellen

Für jede Seite und Richtung einmal, zu zweit oder mit `status` in der Konsole:

1. Beide Madenschrauben zurückdrehen (Spitzen unter den Flächen), dann `tare` ohne Berührung.
2. Den Bass so belasten wie beim Spielen, bis zur Grenzkraft: **etwa 40 N** auf die Oberkante der Handplatte (Drücken, Küchenwaage unter der Handfläche) und **etwa 70 N** am Riemen (Ziehen, Kofferwaage).
3. Unter Last eine Schraube der Seite eindrehen: Die, bei der der Messwert dieser Seite sinkt, ist der Stopp für diese Richtung. Eindrehen, bis der Wert etwas sinkt, dann zurück, bis er sich gerade nicht mehr ändert.
4. Sichern: ein Tropfen mittelfeste Schraubensicherung nur auf die Schraube (nicht auf den Kunststoff, PETG reißt), oder eine zweite Madenschraube als Konter.
5. Andere Richtung, andere Seite; zum Schluss wieder `tare`.

```view
frame: bass
ghost: case
show: contact_pins lever latch_rod
new: stop_screws
cam: 200 -15 0.8
focus: stop_screws
caption: Die vier Madenschrauben M3 (orange), von unten mit einem 1,5er Inbus erreichbar
```

### Kalibrieren

1. `keys`: jede Taste einzeln drücken; jede muss ihre eigene Zeile bewegen.
2. `cal begin`, jede Taste einmal ganz durchdrücken, `cal end` (wird gespeichert).
3. `sign`, dabei die Hälften zusammendrücken (wird gespeichert).
4. `play` und `log on` gegen die Töne des alten Instruments prüfen.

### Verstauen

Zum Tragen den Diskant abnehmen, um 90° drehen, mit den Tasten zur Rückwand des Bass, und von unten in die kurzen Fassungen unter dem Deck schieben, bis die Rastzungen halten. Der Bass deckt dann alle 46 Tasten ab; geladen wird auch so über USB-C.

```view
frame: assembly
show: bass/case bass/back_cover bass/cover bass/keys_static bass/strap
new: store_discant
cam: 215 20
caption: Verstaut: der Diskant hinter dem Bass, 283 × 45 × 152 mm
```
