// The storage gate uses the pinned compiler on CI; existing DevEco installs remain supported.
try { module.exports = require('typescript'); }
catch (_) { module.exports = require('/Applications/DevEco-Studio.app/Contents/tools/hvigor/hvigor/node_modules/typescript'); }
