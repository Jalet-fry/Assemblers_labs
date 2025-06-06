# 🚀 DOS Assembly Projects Collection

## 📌 О проекте
Полная коллекция программ на ассемблере для DOS, включающая:
- 🔧 Исходные коды (.asm)
- ⚡ Готовые исполняемые файлы (.exe)
- 🛠 Автоматизированные скрипты сборки
- 📚 Подробную документацию

## 🧰 Технологии
| Компонент | Версия | Назначение |
|-----------|--------|------------|
| TASM      | 5.0    | Ассемблер  |
| TLINK     | 7.1    | Линкер     |
| Turbo Debugger | 5.5 | Отладчик   |
| Td config | 5.0    | Для удобной и красивой отладки|
| DOSBox    | 0.74   | Эмулятор   |

## 🎯 Быстрый старт
```bash
1)git clone  https://github.com/Jalet-fry/Assemblers_labs.git:
  git lfs pull
  unzip tools.zip -d tools
2)В папках по лабам сами исходники, 
  в tools.zip (для отчаянных домохозяек и бойцов бакуган)
  Инструменты для компиляции и отладки, особенно tdcongig. 
  С ними будет намного проще дебажить. 
3)Рядом с каждым .asm поместите *.exe и td.config, 
  запускаете build Name_of_program без расширения asm.
4)Далее либо простой запуск *.exe в Dosbox,
  либо td.exe из tools и вперед.
5)Маленький совет:при отладке все основные регистры зануляются,
  а в обычном exe наоборот. Не удивляйтесь потом,
  что в debug все ок, а в release ломается. 
6)Зачем lfs pull? LFS оптимизирует загрузку больших файлов,
  хранимых в 1 zip архиве.
