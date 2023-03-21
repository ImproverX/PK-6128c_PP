# Вектор ПК-6128ц++
Вектор ПК-6128ц новодел на базе [восстановленной схемы](https://github.com/ImproverX/PK-6128c). Электронная часть выполнена на трёх платах: процессора, памяти и основной платы, соединяющихся между собой через угловые двухрядные штырьевые разъёмы. Предусмотрена установка двух внутренних плат расширения, например, квази-дисков на 256 кб. Платы выполнены в размере под установку в обычный [корпус ПК Вектор-06ц](https://github.com/ImproverX/Vector06c_case), в качестве клавиатуры используется [плата под ПКМ-1Б или кнопки Черри](https://github.com/ImproverX/Vector-KBD), либо оригинальная клавиатура от Вектора, блок питания -- внешний от Вектора, либо любой на 5В и 2,5А.<br>Обсуждение в [форуме zx-pk.ru](https://zx-pk.ru/threads/34716-reinkarnatsiya-vektor-pk-6128ts.html).

## Содержимое проекта
* [PK6128c_PP.DSN](/PK6128c_PP.DSN) -- обновлённая схема ПК-6128ц++ в формате Proteus 7. В данном ПО возможно частичное моделирование работы схемы. Для корректного открытия схемы потребуется содержимое ПЗУ D10 (К155РЕ3) в бинарном виде [K155RE3.bin](https://github.com/ImproverX/PK-6128c/blob/main/K155PE3.bin) и модель [K155RE3.MDF](https://github.com/ImproverX/PK-6128c/blob/main/K155PE3.MDF) (положите этот файл в "<директория протеуса>\MODELS" для работы моделирования D10 в схеме).
* [PK6128c_PP.LYT](/PK6128c_PP.LYT) -- разводка плат в формате Proteus 7.
* [PK6128c_PP_Shema_P1.png](/PK6128c_PP_Shema_P1.png) и [PK6128c_PP_Shema_P2.png](/PK6128c_PP_Shema_P2.png) -- схема в формате PNG, страница 1 и страница 2.
* [PK6128c_PP_cpu - CADCAM.ZIP](/PK6128c_PP_cpu%20-%20CADCAM.ZIP), [PK6128c_PP_ram - CADCAM.ZIP](/PK6128c_PP_ram%20-%20CADCAM.ZIP) и [PK6128c_PP_main - CADCAM.ZIP](/PK6128c_PP_main%20-%20CADCAM.ZIP) -- гербер-архивы для изготовления плат процессора, памяти и основной платы соответственно.

Нумерация элементов оригинального ПК-6128ц по возможности сохранена, добавленные микросхемы на схеме обозначены U**, резисторы от R200 и далее, конденсаторы от C100 и далее.

## Изменения по отношению к оригинальной схеме ПК-6128ц

* Заменил память на SRAM. Сейчас это сделать проще, чем искать РУ5. Память осталась на 16 бит при чтении видеоданных с задержкой на триггере, как было сделано изначально в ПК-6128. 
* Заменил ПЗУ РФ4А на 64кб 29EE512. Переключение доступа к страницам ПЗУ программное, для этого решил использовать стандартную переключалку области экрана ПК-6128 на порту 0Dh. При отправленном нуле в нулевом бите в этот порт будет подключена область ПЗУ 8000h-FFFFh (по умолчанию при сбросе), при единице -- область 0000h-7FFFh.
* Убрал из схемы сетевую карту. Как оказалось, в некоторых экземплярах ПК-6128ц она не была распаяна, да и в современных реалиях она становится совершенно бесполезной. 
* Убрал контроллер дисковода -- при внешнем подключении не имеет значения, есть ли в ПК встроенный контроллер, или он подключается вместе с флоповодом.
* Заменил все чипы КМОП серий К561 и К1561 на ТТЛ. Кроме того это позволило убрать из схемы несколько резисторов и конденсаторов, требующихся для совмещения уровней сигналов КМОП и ТТЛ.
* Сделал видеовыход на CXA2075, в том числе:
  * Сделал инверсию цвета, исправил строчные синхроимпульсы (ССИ) и выровнял по центру изображение.
  * Немного изменил схему формирования сигнала кадровых синхроимпульсов (КСИ) -- вместо объединения КСИ и ССИ через "исключающее или" использовал свободный триггер.
  * Сделал гасящий синхроимпульс (ГСИ), во время кадра он совпадает с ССИ, и на всю длительность КСИ гасит сигнал.
* Изменил схему записи палитры -- в схеме ПК6128 микросхемы РУ2 были открыты всегда, кроме некоторого времени перед КСИ и в конце КСИ. Теперь РУ2, при отсутствии сигнала записи в порт 0Ch, будут отключаться при ГСИ.
* Попробовал исправить схему работы экрана в режиме 256х512, теоретически получается так: по даташитам задержка на 74ALS00 (D14:A) равна 3..11 (2..8) нс, на 74ALS32 (U10:C) -- 2..14 (3..12) нс, т.е. практически разница должна быть не больше 5 нс и при ширине пикселя 83 нс (в режиме 512) это, думаю, будет незаметно.
* Изменил схему подключения джойстиков -- на ПК6128 был свой вариант, программно несовместимый с существующими. Сделал также, как на Векторе 06ц02, плюс аппаратно совместимыми с [джойстиками Atari/MSX](https://www.msx.org/wiki/General_Purpose_port), на разъёмах D9 (как com-порт).
* Добавил в схему стандартный Векторовский порт ВУ -- с ним можно будет подключать существующее внешнее Векторовское железо, например, тот же комбодевайс. Сигнал СТЕК там формируется по типу адаптеров Z80 для Вектора, он будет подан при командах PUSH, POP и XTHL, чего вполне достаточно для работы КД. Единственно, на этом ВУ не будут работать старые квази-диски, т.к. новая схема не вырабатывает сигналы регенерации памяти.
* Добавил внутреннюю пищалку и AY-3-8910, выход подключён по методу Саттарова В., но только микшируется в моно.
* Добавил часы RTC на DS12885, подключение выполнено по [омской схеме](http://tenroom.ru/scalar/ware/519/index.html) для Вектора, с учётом документации на DS12885.
* D25 заменил на 74HC138 и U24 на 74hc139 -- чипы 74HC155 и аналогичные в исполнении SMD почему-то сложно найти в продаже.
* Разделил схему на платы в соответствии с предложенной [концепцией](https://zx-pk.ru/threads/34546-quot-vektor-pk-6128ts-quot-khotelos-by-uznat-pobolshe.html?p=1159455&viewfull=1#post1159455). Элементы на схеме с фоном из жёлтой штриховки ушли на плату ОЗУ, с голубой штриховкой -- ЦПУ.
* Для сокращения числа контактов между платами внедрил одну из своих прошлых идей, сделал "эмуляцию" ВВ55 на логических элементах U28 и U29, что позволило сократить число линий на 8+5-3=10 шт. И теперь независимо от того, какая конфигурация загружена в ВВ55 на порту 00, запись в порт 03 будет устанавливать сдвиг экрана, запись в порт 02 -- цвет бордюра и режим 512/256. В дополнение, для полного соответствия работе ВВ55, запись в порт 00 конфигурации приводит к обнулению значений в портах 02 и 03, для выключения обнуления портов можно разомкнуть перемычку JP2.

![P1](/PK6128c_PP_Shema_P1.png)<br>
![P2](/PK6128c_PP_Shema_P2.png)
