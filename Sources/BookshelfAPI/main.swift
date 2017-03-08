import Foundation
import Kitura
import HeliumLogger
import SwiftyJSON
import LoggerAPI
import CouchDB

// Initialize Helium
HeliumLogger.use()

setbuf(stdout, nil)
Log.logger = HeliumLogger()

// Create a new router
let router = Router()

// CouchDB connection properties
let connectionProperties = ConnectionProperties(
    host: "localhost",
    port: 5984,
    secured: false,
    username: "khongks",
    password: "passw0rd"
)
let databaseName = "bookshelf_db"

let client = CouchDBClient(connectionProperties: connectionProperties)
let database = client.database(databaseName)
let booksMapper = BooksMapper(withDatabase: database)

router.all("/*", middleware: BodyParser())
router.get("/books", handler: listBooksHandler)
router.get("/books/:id", handler: getBookHandler)
router.post("/books", handler: createBookHandler)
router.put("/books/:id", handler: updateBookHandler)
router.delete("/books/:id", handler: deleteBookHandler)

// Add an HTTP server and connect it to the router
Kitura.addHTTPServer(onPort: 8090, with: router)

// Start the Kitura runloop (this call never returns)
Log.info("Starting server")
Kitura.run()
