'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {".git/COMMIT_EDITMSG": "a08b4247f5d1e0a12ae6f0e21216c7c7",
".git/config": "5497c8e9dce9d3ec966875936a6248a6",
".git/description": "a0a7c3fff21f2aea3cfa1d0316dd816c",
".git/HEAD": "cf7dd3ce51958c5f13fece957cc417fb",
".git/hooks/applypatch-msg.sample": "ce562e08d8098926a3862fc6e7905199",
".git/hooks/commit-msg.sample": "579a3c1e12a1e74a98169175fb913012",
".git/hooks/fsmonitor-watchman.sample": "a0b2633a2c8e97501610bd3f73da66fc",
".git/hooks/post-update.sample": "2b7ea5cee3c49ff53d41e00785eb974c",
".git/hooks/pre-applypatch.sample": "054f9ffb8bfe04a599751cc757226dda",
".git/hooks/pre-commit.sample": "5029bfab85b1c39281aa9697379ea444",
".git/hooks/pre-merge-commit.sample": "39cb268e2a85d436b9eb6f47614c3cbc",
".git/hooks/pre-push.sample": "2c642152299a94e05ea26eae11993b13",
".git/hooks/pre-rebase.sample": "56e45f2bcbc8226d2b4200f7c46371bf",
".git/hooks/pre-receive.sample": "2ad18ec82c20af7b5926ed9cea6aeedd",
".git/hooks/prepare-commit-msg.sample": "2b5c047bdb474555e1787db32b2d2fc5",
".git/hooks/push-to-checkout.sample": "c7ab00c7784efeadad3ae9b228d4b4db",
".git/hooks/sendemail-validate.sample": "4d67df3a8d5c98cb8565c07e42be0b04",
".git/hooks/update.sample": "647ae13c682f7827c22f5fc08a03674e",
".git/index": "1b79b089685fd06d0d87cc23b267e76f",
".git/info/exclude": "036208b4a1ab4a235d75c181e685e5a3",
".git/logs/HEAD": "8f02783602f1679b7849a38c0b16a790",
".git/logs/refs/heads/main": "8f02783602f1679b7849a38c0b16a790",
".git/logs/refs/remotes/origin/main": "ffd57c955b5dea61862c3e8dd388429e",
".git/objects/00/710f68a5a35a68ab814b8c8967fe0bf876265b": "d57dcee0a5cc168a1e01b45b5aef785d",
".git/objects/0b/711280d8d633621864b41ce2248c59387df920": "fcbbd59ffcd982b6532175905e2cbc0b",
".git/objects/0b/7499a99d5efc632f50ce0b73b892e845ce2860": "a8e2c9446abd78de4b0d913500a30718",
".git/objects/0d/edd4e7937b5a3e7ed006cd802fec791280cba8": "e3e04f68dbdeed1a32a63f905400507c",
".git/objects/11/4731d6704926d11c9564f13a9806a759f55952": "c40ec1f3b4dcec2776ccd5e51dbd45cb",
".git/objects/14/69658cf17dc0e607fbade5a4cae9fe23da5b8b": "850ad30e2ecc0cabf31e3ed1537457ff",
".git/objects/17/0b5d19154c9bb60a7d02e5e26d42298bd37b17": "605f152ba7d67733efedf9c4ddf02676",
".git/objects/17/8bac5803c8facf971c3b5bcff298306959108a": "c90fd8d22f60d90951bac7f42c770e74",
".git/objects/17/8d9fa899c45f6037a662b578cfd7f3ee23c204": "406b053f2197d37448ba239c329e99b0",
".git/objects/19/4cdd326e30f51a306d2357e9c91e005853cf7c": "5cc67ce8dba8c47589a4d9b8b23f508d",
".git/objects/1a/1bcf18308231f4db60b3fdb14c9af33f810ba2": "e7399fdd42b3b1f4af76e6a8511dc1c9",
".git/objects/1a/d7683b343914430a62157ebf451b9b2aa95cac": "94fdc36a022769ae6a8c6c98e87b3452",
".git/objects/1b/c3b862efec04fe91f1a97175abc187556adc0a": "7c1703ddb12b6e2815d243ef439f42e2",
".git/objects/20/93931f811420345334d920f34a37fea154eec4": "93e9ec1072dd36274b14677293320bf8",
".git/objects/25/3f4025322e42dfe0a948784f54ba5a01374c07": "da2e268aded035e5cba1c875217b9571",
".git/objects/26/0c97a59f5d8eee27dfb55070eedb9559981cc0": "7ec87e5355dbc5a1e5b919585fc41854",
".git/objects/27/525d887c6d7e68b9fc88b01c42b391e07d2efc": "b5b4a4e712d8840338a86ddfabee8fd4",
".git/objects/32/6f55da64bfb538abec3056ffdb3bca3aa9e53d": "2cad1cfd1b77e1320a41cb7b5405f37c",
".git/objects/34/62293628e2542a5121862ff860f7d74c219be8": "4abb146b950309cde34af60b8c73e05c",
".git/objects/34/72b1933b398999e9a4c8cc81e74ba27c7a89cf": "c166a03dbf4181a9e1cc229605fbfc12",
".git/objects/35/0f28d8cad4de3fbb897ce832cf6c0064cd60ef": "a58ca4675293d0ff397fe73006f181f1",
".git/objects/38/c23cf72ee539b975f4ede6666f484779912659": "4979ecb3989b3164754b485b1cc6f78f",
".git/objects/39/2b890506c985d65b763b1b4c969409fb38ad2c": "1e889a50797b5f8974bd9f1550e24170",
".git/objects/3c/ebbab128a9e094fba7ab561c8ba3c0d0f42166": "72931012b4cc8fe16b1eb194b2e9d182",
".git/objects/44/78320cca469a9dc907050a010c3be43caa99b6": "5f12160be4f6790aa869c61db075f0f2",
".git/objects/46/4ab5882a2234c39b1a4dbad5feba0954478155": "2e52a767dc04391de7b4d0beb32e7fc4",
".git/objects/48/5b549d6b599e182918a3cc05a61ff0a668dc4e": "c4cbffe631de2c219689d102f1fefa37",
".git/objects/4a/4d2c6ebd6aad052855815018ec701424cece3f": "a4beca384ada4c2bbcc12d3d685c19b8",
".git/objects/4c/51fb2d35630595c50f37c2bf5e1ceaf14c1a1e": "a20985c22880b353a0e347c2c6382997",
".git/objects/50/3a1c75d4f5e2fe217ce88a383929dac32ba135": "2a3e7d2eb0b9900454950b8dbda9216a",
".git/objects/50/b130277ff0321d63f781b5c3d92df3522dc29c": "01c86588af2fc352046bd2a1f18c218c",
".git/objects/53/18a6956a86af56edbf5d2c8fdd654bcc943e88": "a686c83ba0910f09872b90fd86a98a8f",
".git/objects/53/3d2508cc1abb665366c7c8368963561d8c24e0": "4592c949830452e9c2bb87f305940304",
".git/objects/59/28def1bebbb5ba9349e579ce60527c7cee0173": "68cc0e7b57f1c5604815563d2a33ed40",
".git/objects/5b/ce905a6cffcf249394c8009f9a3b5c9d57b1b9": "ef29284ac96adf7474a094e0ef7c6fc1",
".git/objects/5f/8e877c981a988e603c123f8258c9af72372196": "9c7b90e58048a436dc89b0840d77ec5d",
".git/objects/62/e69a4f9fe400fc986e37df48a2d7b6fdd5cf10": "578deafbed69c4a189a13256bfdcad1b",
".git/objects/68/3b985d8946fedeeb01df90ebd4f4b8d4f37427": "707eef94bfb326a1dcd2ed57e068d368",
".git/objects/68/c904e2735580cfa6244a401bb162639709c353": "c856af9b61428b88417bc421bb0f6e86",
".git/objects/6b/9862a1351012dc0f337c9ee5067ed3dbfbb439": "85896cd5fba127825eb58df13dfac82b",
".git/objects/6e/cbf3e377884325fd3714fb6275fefbac07b3c0": "496aa446f6c8fe7cf3b8b5c80604e6a8",
".git/objects/6e/e9efe19ee8a7ba917b81a7e83c11b5b9647883": "d75ae82e6586b7fcb42f6e5a0a1e4a01",
".git/objects/70/a234a3df0f8c93b4c4742536b997bf04980585": "d95736cd43d2676a49e58b0ee61c1fb9",
".git/objects/72/1f81a1a3e31340de3d31eff46cba8604f1a7b9": "93e7c80b414f07a447ddd0d20c764eda",
".git/objects/73/c63bcf89a317ff882ba74ecb132b01c374a66f": "6ae390f0843274091d1e2838d9399c51",
".git/objects/76/24ff5db092a0cb6a061e25ebb8735580327dc8": "9d2e2a748ea59325b25c202764e62115",
".git/objects/78/7c65c67bfb94dcc9dd236c3cb8e7655aadc56f": "17e32fb93b6c4d905519afa6d27fe370",
".git/objects/85/8a138e5043fc6cd0e80b4a9e31fcfe7582e564": "652dd0ea6b9fb41b6a8f44fd602e5f17",
".git/objects/88/cfd48dff1169879ba46840804b412fe02fefd6": "e42aaae6a4cbfbc9f6326f1fa9e3380c",
".git/objects/8a/aa46ac1ae21512746f852a42ba87e4165dfdd1": "1d8820d345e38b30de033aa4b5a23e7b",
".git/objects/8e/3c7d6bbbef6e7cefcdd4df877e7ed0ee4af46e": "025a3d8b84f839de674cd3567fdb7b1b",
".git/objects/94/60fd32d151529932f9567c1b2c3a2647a69e9f": "0f0db21e7fc1e58e27daf081c31c9951",
".git/objects/94/f7c14496ea984194b3713c1de32cb6664afc32": "125116142e22dd6c19ee1185136525cf",
".git/objects/99/382c951d33188084170b89286f7d45034f45a6": "7ad84c93b4ae250d17d7bbff9cc093ee",
".git/objects/9a/86f56ef16dd7150f8ea2498eb88f53b36e9367": "7ade34352e2ef6df606229ea130de0c0",
".git/objects/9b/d3accc7e6a1485f4b1ddfbeeaae04e67e121d8": "784f8e1966649133f308f05f2d98214f",
".git/objects/a1/3c27e9343e24207542f256d708f4bba7720c6d": "390565d3952533809ce5baf1ec0d163b",
".git/objects/a2/3cd7fea94b12735bcc087725bff23d83cda49f": "999696dd9e095cae0ad8b82f188c2a63",
".git/objects/a7/c72b3f59a150fd316c367fa5bee019c640ca81": "4362a8eb4b703c26bfbc1acd7aa72646",
".git/objects/a8/68fc415d630208e0761f8a33ff5909f56566a4": "83f7a41fb5c7ad09ad147cba8fea377f",
".git/objects/a9/91f51138ffe059d588003dc7936aff059a0428": "b73a35563fa129bd884d8b5c53ee9231",
".git/objects/ab/82fc56f95edb98c64cb58e881bc4931d688d62": "b3daca181e21abc7020b4be16f4d8b18",
".git/objects/ad/2f90b78480aeb6608226d9db4ecbd3ec06aaeb": "4add97a99941aa0e9eed0f2173416ade",
".git/objects/b0/b30fa34ef53f4cc338cc7ad6173b8eb233c0bd": "91bd1954aae9891d58132256959db2d6",
".git/objects/b1/cde127f1a920558572971c187a7703cf864930": "0e083104c7a1234072749a7c81a62001",
".git/objects/b5/5e90e9456efde2e005e58dfea848134c191aac": "e552af4ceb3e438da065246cc50169f0",
".git/objects/b7/49bfef07473333cf1dd31e9eed89862a5d52aa": "36b4020dca303986cad10924774fb5dc",
".git/objects/b8/2941f7fc5ef1b64b67de85547c0a6f16701cf3": "b21f0a5d484fd4be42f7bfe464d06e3d",
".git/objects/b9/2a0d854da9a8f73216c4a0ef07a0f0a44e4373": "f62d1eb7f51165e2a6d2ef1921f976f3",
".git/objects/b9/6a5236065a6c0fb7193cb2bb2f538b2d7b4788": "4227e5e94459652d40710ef438055fe5",
".git/objects/ba/390a72c0de2f5abdd83fb5596253d2b142315f": "92f4a17fef3fd1e187c0a17e0a3f3985",
".git/objects/be/5db4d7068d335141e3da4bbdcae46a2292e210": "ba775d2afad4e1121a72f977c4821e64",
".git/objects/c3/83617e7f07860fdc527d185da8c159bd0111a4": "3efc9a7ba27bf231e34b0b6e04f84d92",
".git/objects/c8/08fb85f7e1f0bf2055866aed144791a1409207": "92cdd8b3553e66b1f3185e40eb77684e",
".git/objects/c9/b3ca5bbddf75a82e4f7e00ae54329cbf6c4e92": "1f1c65492cfbae27b5438b40189ba7a9",
".git/objects/cb/a8ed57a558ff67548c069ada37f2ca732b4af1": "9f4b6a0b2b3b7c86392d7259cdf7a202",
".git/objects/cc/fab74c1f56c330985060e2247607eaedb3c7d7": "ad5b6117df489509af208438785f208b",
".git/objects/ce/f5cd15dfa55c058a73547388f38aa6d30d5fa6": "9730bb8d251ded50c1f176bba55b5b8f",
".git/objects/ce/fdcaaeece742e25e8a903f05a06a8128718b74": "35c79b00e2ad014d797f67af2a33b1ca",
".git/objects/d4/3532a2348cc9c26053ddb5802f0e5d4b8abc05": "3dad9b209346b1723bb2cc68e7e42a44",
".git/objects/d5/d09c52774de771585b86c12eddf7778a88b68d": "0bd60c65c1b1465bae3fdab5eb54dffe",
".git/objects/d6/9c56691fbdb0b7efa65097c7cc1edac12a6d3e": "868ce37a3a78b0606713733248a2f579",
".git/objects/d7/d9559d3d973786db5af3fbd2511244e47b1b31": "7447da5c8ed76ce3cdfa0cd4b6f2bba2",
".git/objects/dc/11fdb45a686de35a7f8c24f3ac5f134761b8a9": "761c08dfe3c67fe7f31a98f6e2be3c9c",
".git/objects/dd/7b02750c4cacaefa1b625b850c6f6da86e9abc": "bc4c665d36faf59b178291748282559c",
".git/objects/df/4ae4e8c4bda478b830c89de0507945aef8b4d3": "3948057b6d25a2a87a065be4298d26c5",
".git/objects/e0/7ac7b837115a3d31ed52874a73bd277791e6bf": "74ebcb23eb10724ed101c9ff99cfa39f",
".git/objects/e3/78931b2ef93ba0827c57306a115da2fcb51c87": "c686ee61de93f6c3727c0837570f01eb",
".git/objects/e3/91c881139fca8d3a1513a5d1de94a66a66e174": "09c9c6e9690095c07e2f4de86576225f",
".git/objects/e8/571e2cfe91165462f283c8aa477a89166f6ac4": "ee34eed70f5180bcb39f188384bf9f7b",
".git/objects/e9/94225c71c957162e2dcc06abe8295e482f93a2": "2eed33506ed70a5848a0b06f5b754f2c",
".git/objects/eb/9b4d76e525556d5d89141648c724331630325d": "37c0954235cbe27c4d93e74fe9a578ef",
".git/objects/f2/04823a42f2d890f945f70d88b8e2d921c6ae26": "6b47f314ffc35cf6a1ced3208ecc857d",
".git/objects/f2/a59e48cf462114c8eed9e3ac6fff24c8aa3d5e": "39a96ae0b1b09e3579c13f7a462e56ad",
".git/objects/f2/b213321d360afaf09453f2f364e44a7080efa9": "b10f2eba3b93c447fcea2f363901e360",
".git/objects/f5/72b90ef57ee79b82dd846c6871359a7cb10404": "e68f5265f0bb82d792ff536dcb99d803",
".git/objects/fe/6df959251f2ea8e6008d9be88c7c92d9914a20": "5235f7733092d8810e0d60e764f08a9b",
".git/refs/heads/main": "64c432ccb079ae90046919655f7761ed",
".git/refs/remotes/origin/main": "64c432ccb079ae90046919655f7761ed",
"assets/AssetManifest.bin": "1fe78d99099ee4407478e70a08513c6f",
"assets/AssetManifest.bin.json": "e44bb50a0b122ee5f3666674fa966327",
"assets/AssetManifest.json": "4fc41e07eb7fb3b22fbcb8eb9b64ee27",
"assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/fonts/MaterialIcons-Regular.otf": "beba4a7ada8efb34f931eb932c3e29b6",
"assets/NOTICES": "717b716b5f15d376621a32a4e02227d7",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/packages/media_kit/assets/web/hls1.4.10.js": "bd60e2701c42b6bf2c339dcf5d495865",
"assets/packages/wakelock_plus/assets/no_sleep.js": "7748a45cd593f33280669b29c2c8919a",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"canvaskit/canvaskit.js": "728b2d477d9b8c14593d4f9b82b484f3",
"canvaskit/canvaskit.js.symbols": "bdcd3835edf8586b6d6edfce8749fb77",
"canvaskit/canvaskit.wasm": "7a3f4ae7d65fc1de6a6e7ddd3224bc93",
"canvaskit/chromium/canvaskit.js": "8191e843020c832c9cf8852a4b909d4c",
"canvaskit/chromium/canvaskit.js.symbols": "b61b5f4673c9698029fa0a746a9ad581",
"canvaskit/chromium/canvaskit.wasm": "f504de372e31c8031018a9ec0a9ef5f0",
"canvaskit/skwasm.js": "ea559890a088fe28b4ddf70e17e60052",
"canvaskit/skwasm.js.symbols": "e72c79950c8a8483d826a7f0560573a1",
"canvaskit/skwasm.wasm": "39dd80367a4e71582d234948adc521c0",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"flutter.js": "83d881c1dbb6d6bcd6b42e274605b69c",
"flutter_bootstrap.js": "b3b2d5ee908b8b2672dd52d021e4d985",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"index.html": "cdc6111bf02df90e56d9bedee50338d4",
"/": "cdc6111bf02df90e56d9bedee50338d4",
"main.dart.js": "af64670421f30546fa0b77fa90a4a5a8",
"manifest.json": "72a0d774bcdb1b44fbd1e76715460452",
"playlists/arabic.m3u": "b5f4adda5f800a2ac2049b4926bf5394",
"version.json": "710a7c1c2ea5e5bf459781a4438476f7"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
