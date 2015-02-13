## Для начала

### Обязательно
0. Установить свежий haxe из исходников
    * Выкачать [исходники отсюда](https://github.com/HaxeFoundation/haxe)
    * Ознакомиться с [мануалом по сборке](http://haxe.org/documentation/introduction/building-haxe.html)
    * Для сборки ocaml может понадобиться `autoconf-2.13`, доступный в homebrew на OS X
0. Перейти в папку `haxe/build/`
0. Выполнить команду `haxe build.hxml`
0. Перейти в папку `node/`
0. Выполнить команду `npm install`
0. Перейти в папку `ruby/`
0. Установить руби нужной версии (см. файл .ruby-version)
0. Выполнить команду `gem install bundler`
0. Выполнить команду `bundle install`
0. Выполнить команду `rackup config.ru -p 7788`
0. Открыть в браузере страницу [http://127.0.0.1:7788/](http://127.0.0.1:7788/)


### Не обязательно
0. Установить [VirtualBox](https://www.virtualbox.org/)
0. Установить [Vagrant](https://www.vagrantup.com/)
0. Перейти в корень проекта
0. vagrant plugin install vagrant-librarian-chef
0. vagrant plugin install vagrant-omnibus
0. vagrant up
 
Если BIOS не поддерживает VT-x, нужно выполнить команды
```
VBoxManage modifyvm <vmname> --longmode off
VBoxManage modifyvm <vmname> --hwvirtex off
```
иначе виртуальная машина не запустится.
