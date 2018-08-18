# Zotero Project

Zotero is an awesome reference manager (knowledge manager). This is my scafolding repo for quick development.

## My change logs

Quick pointers in latest first order: (screenshots can be found in commit comment thread)

* [Plaintext version item-in-collection list](https://github.com/hupili/zotero/commit/0d21e14aaf5605955384ec402f58904c18480968)

## Lightning notes for developers and myself

* Start with [building_the_standalone_client](https://www.zotero.org/support/dev/client_coding/building_the_standalone_client). Or simply checkout the `Makefile` of this repo that implements those steps in official doc.
* [Client coding reference](https://www.zotero.org/support/dev/client_coding)
* [Modify a packaged release](https://www.zotero.org/support/dev/modifying_zotero_files) (`.jar`) of Zotero client
* If you followed the above guide or my `Makefile`, run your customised Zotero as: `./zotero-standalone-build/staging/Zotero.app/Contents/MacOS/zotero`.
* Methods for debugging:
  * [via Firefox Web Console](https://groups.google.com/d/msg/zotero-dev/qvBK2YEIj_c/2JV25EDrAgAJ) - you need to run with `-debugger` option. (not tested yet)
  * jsconsole: run with `--jsconsole` option. (not tested yet)
  * try-print-modify that every developer is familiar and applicable to all languages. Run with `-ZoteroDebugText`. In the code, use `Zotero.debug()` to output anything of interest.
* Local data file:
  * Storage roo: `$HOME/Zotero/`
  * Main SQLite DB: `$HOME/Zotero/zotero.sqlite`
  * Files: can be found in hashed paths in `$HOME/Zotero/storage`
* Future pointers:
  * Looks like a turnkey solution ([docker-compose.yml](https://github.com/mrtcode/zotero-server/blob/master/docker-compose.yml)) to run a full set of Zotero backend components: https://github.com/mrtcode/zotero-server .
  * The [official Docker repo](https://hub.docker.com/u/zotero/) that contains part of the server components.
  * Plugins:
    * [Sample plugin](https://www.zotero.org/support/dev/sample_plugin)
    * Graph viz plugin: [zotnet](https://people.ucsc.edu/~cmbyrd/zotnet.php)
    * Text viz plugin (for Voyant): [zotero-voyant-export](https://github.com/corajr/zotero-voyant-export)

### Code structure

Zotero, originally emerged as a Firefox plugin/ Firefox appliation, is coded in Javascript. It is fortuante that the App was developed before outburst of FE frameworks, so non FE developer (like me), with some basic JS skills is able to modify it. Here's a quick reference of code structure, which I did not find online. Hope it saves the next guy some time.

The UI is coded in [XUL](https://en.wikipedia.org/wiki/XUL), an HTML like (actually XML) language that one can readily understand without knowing the term of "XUL".

In most cases, you only need to modify files in `chrome/content/zotero`. Note that people [call XUL applications running locally as "chrome"](https://en.wikipedia.org/wiki/XUL#cite_ref-11), hence the folder name. It is not referring to the browser called Google Chrome.

Assume our current dir is `chrome/content/zotero` in following discussions.

```shell
%tree . -L 2 -d
.
├── bindings
├── import
│   └── mendeley
├── ingester
├── integration
├── locale
│   └── csl
├── preferences
├── standalone
├── test
├── tools
│   └── testTranslators
└── xpcom
    ├── connector
    ├── data
    ├── rdf
    ├── storage
    ├── sync
    ├── translation
    └── xregexp
```

Most interesting UI components:

* ./xpcom/collectionTreeRow.js -- left pane
* ./xpcom/collectionTreeView.js -- left pane
* ./itemPane.xul -- right pane
* ./itemPane.js -- right pane
* ./zoteroPane.xul -- middle pane
* ./zoteroPane.js -- middle pane

Other files of interest:

* `./xpcom/data/*` -- good reference for data models
* `../../locale` -- locales. When you reference a string in XUL using `$...` notation, the runtime finds the strings here. (Question: how to maintain consistency of those files? Automatic scan of different keys?)

### Modify UI

Two ways:

* Modify `.xul` files
* In `.js` files, use HTML-like DOM operation to manipulate the UI. Common functions:
  * `document.createElement()`
  * `document.appendChild()`
  * `el.removeChild()`
  * `el.setAttribute()`

### Global objects

Those objets are available globally:

* `ZoteroPane_Local` -- reference panes from this object
* `Zotero` -- access Zotero functions from this object, e.g. DB connection and query.

### Data model (schema)

Just checkout the DB, `$HOME/Zotero/zotero.sqlite`:

```shell
%sqlite3 $HOME/Zotero/zotero.sqlite
SQLite version 3.19.3 2017-06-27 16:48:08
Enter ".help" for usage hints.
sqlite> .table
annotations                itemNotes                
baseFieldMappings          itemRelations            
baseFieldMappingsCombined  itemTags                 
charsets                   itemTypeCreatorTypes     
collectionItems            itemTypeFields           
collectionRelations        itemTypeFieldsCombined   
collections                itemTypes                
creatorTypes               itemTypesCombined        
creators                   items                    
customBaseFieldMappings    libraries                
customFields               proxies                  
customItemTypeFields       proxyHosts               
customItemTypes            publicationsItems        
deletedItems               relationPredicates       
feedItems                  savedSearchConditions    
feeds                      savedSearches            
fieldFormats               settings                 
fields                     storageDeleteLog         
fieldsCombined             syncCache                
fileTypeMimeTypes          syncDeleteLog            
fileTypes                  syncObjectTypes          
fulltextItemWords          syncQueue                
fulltextItems              syncedSettings           
fulltextWords              tags                     
groupItems                 transactionLog           
groups                     transactionSets          
highlights                 transactions             
itemAttachments            translatorCache          
itemCreators               users                    
itemData                   version                  
itemDataValues           
sqlite> .schema collections
CREATE TABLE collections (    collectionID INTEGER PRIMARY KEY,    collectionName TEXT NOT NULL,    parentCollectionID INT DEFAULT NULL,    clientDateModified TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,    libraryID INT NOT NULL,    key TEXT NOT NULL,    version INT NOT NULL DEFAULT 0,    synced INT NOT NULL DEFAULT 0,    UNIQUE (libraryID, key),    FOREIGN KEY (libraryID) REFERENCES libraries(libraryID) ON DELETE CASCADE,    FOREIGN KEY (parentCollectionID) REFERENCES collections(collectionID) ON DELETE CASCADE);
```

### DB query

Following is a Promise for DB query:

```javascript
Zotero.DB.queryAsync(sql, sqlParams)
```

* `sql` is the raw SQL string, using `?` as placeholder for params
* sqlParams - sqlParams

Invoke pattern **ascynchronousely**:

```javascript
var myResult = Zotero.DB.queryAsync(sql, sqlParams).then(r => {
  // Do something with r: ResultSet
  myResult = r[0].collectionName; // 0-th row, "collectionName" column
  return myResult
})
```

`r` is a list/ an array of [MozIStorageRow](https://developer.mozilla.org/en-US/docs/Mozilla/Tech/XPCOM/Reference/Interface/MozIStorageRow) whose columns can be accessed by `getResultByIndex()` or `getResultByName()`.

### General asynchronous invoke pattern (co-routine)

Co-routine is extensively used in this project, as an efficiency measure. Programmers can intentionally "give way" to other code blocks when current code block is waiting for something.

```javascript
Zotero.Promise.coroutine(function*() {
  // Do something here
  // ...
  var results = yield callCoroutineFromZotero(params)
  results.next()
  // or
  results.map(((input) => {
    return output;
  })
})();
```

Note:

* `function*()`
* `yield`
* Last `()`
