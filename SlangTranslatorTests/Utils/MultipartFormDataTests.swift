//
//  MultipartFormDataTests.swift
//  SlangTranslatorTests
//
//  Tests for MultipartFormData utility.
//

import Testing
import Foundation
@testable import SLNG

struct MultipartFormDataTests {

    // MARK: - Basic Build Tests

    @Test func build_createsValidMultipartData() async throws {
        let boundary = "TestBoundary123"
        let fileData = "test audio content".data(using: .utf8)!

        let result = MultipartFormData.build(
            boundary: boundary,
            fileFieldName: "audio",
            fileName: "recording.m4a",
            mimeType: "audio/m4a",
            fileData: fileData
        )

        let resultString = String(data: result, encoding: .utf8)!

        // Verify boundary markers
        #expect(resultString.contains("--\(boundary)"))
        #expect(resultString.contains("--\(boundary)--"))

        // Verify content disposition
        #expect(resultString.contains("Content-Disposition: form-data"))
        #expect(resultString.contains("name=\"audio\""))
        #expect(resultString.contains("filename=\"recording.m4a\""))

        // Verify content type
        #expect(resultString.contains("Content-Type: audio/m4a"))

        // Verify file data is included
        #expect(resultString.contains("test audio content"))
    }

    @Test func build_includesAdditionalFields() async throws {
        let boundary = "TestBoundary"
        let fileData = "content".data(using: .utf8)!

        let result = MultipartFormData.build(
            boundary: boundary,
            fileFieldName: "file",
            fileName: "test.txt",
            mimeType: "text/plain",
            fileData: fileData,
            additionalFields: [
                "language": "id",
                "format": "m4a"
            ]
        )

        let resultString = String(data: result, encoding: .utf8)!

        // Verify additional fields are included
        #expect(resultString.contains("name=\"language\""))
        #expect(resultString.contains("id"))
        #expect(resultString.contains("name=\"format\""))
        #expect(resultString.contains("m4a"))
    }

    @Test func build_handlesEmptyFileName() async throws {
        let boundary = "Boundary"
        let fileData = Data()

        let result = MultipartFormData.build(
            boundary: boundary,
            fileFieldName: "audio",
            fileName: "",
            mimeType: "audio/m4a",
            fileData: fileData
        )

        let resultString = String(data: result, encoding: .utf8)!

        #expect(resultString.contains("filename=\"\""))
    }

    @Test func build_handlesBinaryData() async throws {
        let boundary = "TestBoundary"
        // Create some binary data that's not valid UTF-8
        let fileData = Data([0x00, 0x01, 0x02, 0xFF, 0xFE, 0xFD])

        let result = MultipartFormData.build(
            boundary: boundary,
            fileFieldName: "audio",
            fileName: "binary.bin",
            mimeType: "application/octet-stream",
            fileData: fileData
        )

        // Result should contain the binary data
        #expect(result.count > fileData.count)
    }

    // MARK: - Structure Tests

    @Test func build_startsWithBoundary() async throws {
        let boundary = "StartBoundary"
        let fileData = "content".data(using: .utf8)!

        let result = MultipartFormData.build(
            boundary: boundary,
            fileFieldName: "file",
            fileName: "test.txt",
            mimeType: "text/plain",
            fileData: fileData
        )

        let resultString = String(data: result, encoding: .utf8)!

        #expect(resultString.hasPrefix("--\(boundary)"))
    }

    @Test func build_endsWithClosingBoundary() async throws {
        let boundary = "EndBoundary"
        let fileData = "content".data(using: .utf8)!

        let result = MultipartFormData.build(
            boundary: boundary,
            fileFieldName: "file",
            fileName: "test.txt",
            mimeType: "text/plain",
            fileData: fileData
        )

        let resultString = String(data: result, encoding: .utf8)!

        #expect(resultString.contains("--\(boundary)--"))
    }

    // MARK: - MIME Type Tests

    @Test func build_includesCorrectMimeType() async throws {
        let testCases: [(mimeType: String, expected: String)] = [
            ("audio/m4a", "Content-Type: audio/m4a"),
            ("audio/wav", "Content-Type: audio/wav"),
            ("audio/mp3", "Content-Type: audio/mp3"),
            ("application/json", "Content-Type: application/json"),
        ]

        for testCase in testCases {
            let result = MultipartFormData.build(
                boundary: "Test",
                fileFieldName: "file",
                fileName: "test",
                mimeType: testCase.mimeType,
                fileData: Data()
            )

            let resultString = String(data: result, encoding: .utf8)!
            #expect(resultString.contains(testCase.expected))
        }
    }

    // MARK: - RFC Compliance Tests

    @Test func build_usesCorrectLineEndings() async throws {
        let boundary = "Boundary"
        let fileData = "test".data(using: .utf8)!

        let result = MultipartFormData.build(
            boundary: boundary,
            fileFieldName: "file",
            fileName: "test.txt",
            mimeType: "text/plain",
            fileData: fileData
        )

        let resultString = String(data: result, encoding: .utf8)!

        // RFC 2046 specifies CRLF (\r\n) as line ending
        #expect(resultString.contains("\r\n"))
    }
}
