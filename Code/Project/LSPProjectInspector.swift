import LSPServiceAPI
import SwiftLSP
import FoundationToolz
import Foundation
import SwiftObserver
import SwiftyToolz

class LSPProjectInspector: ProjectInspector
{
    init(language: String, folder: URL) throws
    {
        self.language = language
        self.rootFolder = folder
        serverConnection = try LSPServiceAPI.Language.Name(language).connectToLSPServer()
        
        serverConnection.serverDidSendNotification = { _ in }

        serverConnection.serverDidSendErrorOutput =
        {
            errorOutput in log(error: "Language server: \(errorOutput)")
        }
        
        serverConnection.serverDidSendError = { log($0) }
    }
    
    func symbols(for codeFile: CodeFolder.File) -> SymbolPromise
    {
        promise
        {
            initialization
        }
        .onSuccess
        {
            let file = URL(fileURLWithPath: codeFile.path)
            
            let document: [String: JSONObject] =
            [
                "uri": file.absoluteString, // DocumentUri;
                "languageId": self.language, // TODO: make enum for LSP language keys, and struct for this document
                "version": 1,
                "text": codeFile.content
            ]
            
            try self.serverConnection.notify(.didOpen(doc: JSON(document)))
            
            return Promise
            {
                promise in
            
                do
                {
                    try self.serverConnection.request(.docSymbols(inFile: file),
                                                      as: [LSPDocumentSymbol].self)
                    {
                        do { promise.fulfill(try $0.get()) }
                        catch { promise.fulfill(error) }
                    }
                }
                catch { promise.fulfill(error) }
            }
        }
    }
    
    // MARK: - Initializing the Language Server
    
    private lazy var initialization = initializeServer()
    
    private func initializeServer() -> ResultPromise<Void>
    {
        promise
        {
            LSPServiceAPI.ProcessID.get()
        }
        .onSuccess
        {
            self.initializeServer(withClientProcessID: $0)
        }
    }
    
    private func initializeServer(withClientProcessID id: Int) -> ResultPromise<Void>
    {
        Promise
        {
            promise in
            
            do
            {
                try serverConnection.request(.initialize(folder: rootFolder,
                                                         clientProcessID: id))
                {
                    [weak self] _ in
                    
                    do
                    {
                        guard let self = self else { throw "\(Self.self) died" }
                        try self.serverConnection.notify(.initialized)
                        promise.fulfill(())
                    }
                    catch { promise.fulfill(error) }
                }
            }
            catch { promise.fulfill(error) }
        }
    }
    
    // MARK: - Basic Configuration
    
    private let language: String
    private let rootFolder: URL
    private let serverConnection: LSP.ServerConnection
}
