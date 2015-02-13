/**
 * Вся эта фиговина (ниже) не будет работать без конфига.
 * Конфиг должен быть .yml-файлом, иначе фиговине тоже работать не захочется.
 * Конфиг должен быть передан в параметры запуска, но об этом сообщит сама фиговина.
 * Я же просто расскажу что должно быть в конфиге:
 *
 * 1) logicPath - строка с путем до шаред-логики. Путь относительно этого файла.
 * 2) defaultVersion - строка с именем дефолтной версии шаред-логики
 * 3) allowedExchangables - массив строк с разрешеннами типами объектов обмена (gifts, wishes, etc.)
 * 4) allowedActions - массив строк с разрешенными в данной песочнице действиями (читы, например)
 */


var path = require('path');
var net = require('net');
var fs = require('fs');
var yaml = require("js-yaml");
var argv = require('optimist')
            .usage('Usage: $0 -s path_to_socket -c path_to_config_file.yml')
            .demand(['s', 'c'])
            .argv;

var SocketChannel = require('./lib/SocketChannel');


var sockPath = path.normalize(argv.s);
var config = yaml.safeLoad(fs.readFileSync(path.normalize(argv.c), 'utf8'));

var channel = new SocketChannel(sockPath, config);
