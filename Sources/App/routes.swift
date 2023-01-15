import Vapor
import Foundation
import WalletPassGenerator

struct NewPassRequest: Content {
    var title: String
    var titleValue: String
}

func routes(_ app: Application) throws {
    app.get { req async in
        "It works!"
    }
    
    app.post("generate_pass") { req async throws in
        debugPrint("[pass] directory \(app.directory.workingDirectory)")
        let content = try req.content.decode(NewPassRequest.self)
        do {
            try generatePass(title: content.title, titleValue: content.titleValue)
            let res = req.fileio.streamFile(at: app.directory.resourcesDirectory + "pass3.9/hug_pass.pkpass")
            res.headers.replaceOrAdd(name: .contentType, value: "application/vnd.apple.pkpass")
            return res
        } catch {
            throw error
        }
    }
    
    app.get("current_pass") { req async in
        let res = req.fileio.streamFile(at: app.directory.resourcesDirectory + "pass3.9/hug_pass.pkpass")
        res.headers.replaceOrAdd(name: .contentType, value: "application/vnd.apple.pkpass")
        return res
    }
    
    @discardableResult
    func generatePass(title: String,
                      titleValue: String) throws -> Data? {
        let pass = Pass(
            formatVersion: 2,
            passTypeIdentifier: "pass.com.hugpass", // the same identifier used to create the certificate
            serialNumber: UUID().uuidString,
            teamIdentifier: "74BYKALB88", // TeamID of your apple developer account,
            organizationName: "Pass App",
            description: "This is a test description",
            logoText: "HanyPASS",
            foregroundColor: .rgb(r: 0, g: 0, b: 0),
            backgroundColor: .rgb(r: 255, g: 255, b: 255),
            labelColor: .rgb(r: 20, g: 85, b: 161),
            barcodes: [],
            genericPass: PassContent(primaryFields: [Field(key: "title", label: title, value: titleValue)])
        )
        
        debugPrint("[pass] Pass created: \(pass)")
        
        guard let pkPassURL = URL(string: app.directory.resourcesDirectory + "pass3.9/") else { return nil }
                
        do {
            let passData = try PassGenerator.generatePass(
                pass,
                named: "hug_pass.pkpass",
                at: pkPassURL,
                certificateName: "Certificates.p12",
                wwdrCertificateName: "WWDR.pem",
                assets: [
                    "logo.png",
                    "logo@2x.png",
                    "strip.png",
                    "strip@2x.png",
                    "icon.png",
                    "icon@2x.png",
                ]
            )
            debugPrint("[pass] Pass generated: \(String(describing: passData))")
            return passData
        } catch {
            debugPrint("[pass] error \(error)")
            throw error
        }
    }
}
