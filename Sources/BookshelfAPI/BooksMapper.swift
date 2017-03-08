//
//  BookMapper.swift
//  BookshelfAPI
//
//  Created by khongks on 7/3/17.
//
//
import CouchDB
import Foundation
import LoggerAPI
import SwiftyJSON

class BooksMapper {
    
    enum RetrieveError: Error {
        case NotFound
        case Unknown
        case Invalid(String)
    }
    
    enum UpdateError: Error {
        case NotFound
        case Unknown
        case Invalid(String)
    }
    
    let database: Database;
    
    init(withDatabase db: Database) {
        self.database = db
        Log.info("BooksMapper initialized")
    }
    
    ///
    /// Fetch all books using the books/all view
    ///
    func fetchAll() -> [Book]? {
        Log.info("BooksMapper fetchAll called")
        var books: [Book]?
        
        database.queryByView("all_books", ofDesign: "main_design", usingParameters: []) {
            (document: JSON?, error: NSError?) in
            if let document = document {
                // create an array of Books from document
                Log.info("BooksMapper fetchAll document found")
                if let list = document["rows"].array {
                    books = list.map {
                        let data = $0["value"];
                        let bookId = data["_id"].stringValue + ":" + data["_rev"].stringValue                        
                        return Book(id: bookId, title: data["title"].stringValue,
                                    author: data["author"].stringValue, isbn: data["isbn"].stringValue)
                    }
                } else {
                    Log.error("No documents fetched!")
                }
            } else {
                Log.error("Something went wrong; could not fetch all books.")
                if let error = error {
                    Log.error("CouchDB error: \(error.localizedDescription). Code: \(error.code)")
                }
            }
        }
        
        return books
    }
    
    
    ///
    /// Fetch a single book using the books/all view
    ///
    func fetchBook(withId id: String) throws -> Book {
        
        // The id contains both the id and the rev separated by a :, so split
        let parts = id.characters.split { $0 == ":"}.map(String.init)
        let bookId = parts[0]
        
        var book: Book?
        var error: RetrieveError = RetrieveError.Unknown
        database.retrieve(bookId, callback: { (document: JSON?, err: NSError?) in
            
            if let document = document {
                let bookId = document["_id"].stringValue + ":" + document["_rev"].stringValue
                book = Book(id: bookId, title: document["title"].stringValue,
                            author: document["author"].stringValue, isbn: document["isbn"].stringValue)
                return
            }
            
            if let err = err {
                switch err.code {
                case 404: // not found
                    error = RetrieveError.NotFound
                default: // some other error
                    Log.error("Oops something went wrong; could not read document.")
                    Log.info("Error: \(err.localizedDescription). Code: \(err.code)")
                }
            }
        })
        
        if book == nil {
            throw error
        }
        
        return book!
    }
    
    ///
    /// Add a book to the database
    ///
    func insertBook(json: JSON) throws -> Book {
        // validate required values
        guard let title = json["title"].string,
            let author = json["author"].string else {
                throw RetrieveError.Invalid("A Book must have a title and an author")
        }
        // optional values
        let isbn = json["isbn"].stringValue
        
        // create a JSON object to store which contains just the properties we need
        let bookJson = JSON([
            "type": "book",
            "author": author,
            "title": title,
            "isbn": isbn,
            ])
        
        var book: Book?
        database.create(bookJson) { (id, revision, document, err) in
            if let id = id, let revision = revision, err == nil {
                Log.info("Created book \(title) with id of \(id)")
                let bookId = "\(id):\(revision)"
                book = Book(id: bookId, title: title, author: author, isbn: isbn)
                return
            }
            
            Log.error("Oops something went wrong; could not create book.")
            if let err = err {
                Log.info("Error: \(err.localizedDescription). Code: \(err.code)")
            }
        }
        
        if book == nil {
            throw RetrieveError.Unknown
        }
        
        return book!
    }
    
    ///
    /// Update a book to the database
    ///
    func updateBook(withId id: String, json: JSON) throws -> Book {
        Log.info("updateBook: id=\(id)")
        Log.info("updateBook: json=\(json.rawString())")
        
        // The id contains both the id and the rev separated by a :, so split
        let parts = id.characters.split { $0 == ":"}.map(String.init)
        let bookId = parts[0]
        
        Log.info("updateBook: bookId=\(bookId)")
        
        var book: Book?
        var error: RetrieveError = RetrieveError.Unknown
        database.retrieve(bookId, callback: { (document: JSON?, err: NSError?) in
            
            if let document = document {
                let bookId = document["_id"].stringValue + ":" + document["_rev"].stringValue
                
                Log.info("updateBook: bookId=\(bookId)")
                Log.info("updateBook: document=\(document.rawString())")
                
                var type, author, title, isbn: String
                if json["type"].stringValue != "" { type = json["type"].stringValue }
                else { type = document["type"].stringValue }
                if json["title"].stringValue != "" { title = json["title"].stringValue }
                else { title = document["title"].stringValue }
                if json["author"].stringValue != "" { author = json["author"].stringValue }
                else { author = document["author"].stringValue }
                if json["isbn"].stringValue != "" { isbn = json["isbn"].stringValue }
                else { isbn = document["isbn"].stringValue }

                // create a JSON object to store which contains just the properties we need
                let bookJson = JSON([
                    "type": type,
                    "author": author,
                    "title": title,
                    "isbn": isbn
                    ])

                Log.info("updateBook: bookJson=\(bookJson.rawString())")

                self.database.update(document["_id"].stringValue,
                                     rev: document["_rev"].stringValue,
                                     document: bookJson,
                                     callback: { (rev, document: JSON?, err: NSError?) in
                                        
                    Log.info("updateBook: document=\(document?.rawString())")

                                        
                    book = Book(id: bookId, title: (document?["title"].stringValue)!, author: (document?["author"].stringValue)!, isbn: (document?["isbn"].stringValue)!)
                    
                    return
                })
            }
            
            if let err = err {
                switch err.code {
                case 404: // not found
                    error = RetrieveError.NotFound
                default: // some other error
                    Log.error("Oops something went wrong; could not read document.")
                    Log.info("Error: \(err.localizedDescription). Code: \(err.code)")
                }
            }
        })
        
        if book == nil {
            throw error
        }
        return book!
    }
    
    
    ///
    /// Fetch a single book using the books/all view
    ///
    func removeBook(withId id: String) throws -> Book {
        Log.info("removeBook: \(id)")

        
        // The id contains both the id and the rev separated by a :, so split
        let parts = id.characters.split { $0 == ":"}.map(String.init)
        let bookId = parts[0]
        let rev = parts[1]
        
        var book: Book?
        var error: RetrieveError = RetrieveError.Unknown

        database.retrieve(id) {
            doc, err in

            if let doc = doc {
                let bookId = document["_id"].stringValue + ":" + document["_rev"].stringValue
                book = Book(id: id,
                            title: doc["title"].stringValue,
                            author: doc["author"].stringValue,
                            isbn: doc["isbn"].stringValue)
                
                Log.info("removeBook: \(book?.toJSON())")
                Log.info("bookId=\(bookId), rev=\(rev)")
                //let rev = doc["_rev"].stringValue
                self.database.delete(bookId, rev: rev) {
                    err in
                    if let err = err {
                        Log.error("Oops something went wrong; could not delete document.")
                        Log.info("Error: \(err.localizedDescription). Code: \(err.code)")
                    } else {
                        Log.info("Document deleted")
                    }
                }
            }
            if let err = err {
                switch err.code {
                case 404: // not found
                    error = RetrieveError.NotFound
                default: // some other error
                    Log.error("Oops something went wrong; could not read document.")
                    Log.info("Error: \(err.localizedDescription). Code: \(err.code)")
                }
            }

        }
        if book == nil {
            throw error
        }
        
        return book!
    }
}
