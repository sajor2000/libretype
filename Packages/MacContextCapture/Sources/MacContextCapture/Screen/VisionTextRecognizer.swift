//
//  VisionTextRecognizer.swift
//  MacContextCapture
//
//  Shared, fail-open execution boundary for Vision OCR. VNImageRequestHandler.perform is a
//  synchronous API even when wrapped in an async function, so it must never inherit MainActor.
//

import CoreGraphics
import Foundation
import Vision

struct VisionRecognizedText: Sendable {
    var text: String
    var confidence: Float
    var boundingBox: CGRect
}

enum VisionTextRecognitionError: Error, Equatable {
    case busy
    case timedOut
}

/// Rejects overlapping OCR rather than queueing it. If Apple's text recognizer wedges, the active
/// permit intentionally remains held until the native call really returns; later captures then
/// fail open instead of accumulating work behind it.
actor VisionTextRecognitionCoordinator {
    private var isActive = false

    func begin() throws {
        guard !isActive else { throw VisionTextRecognitionError.busy }
        isActive = true
    }

    func finish() {
        isActive = false
    }
}

enum VisionTextRecognizer {
    private static let coordinator = VisionTextRecognitionCoordinator()
    private static let timeoutNanoseconds: UInt64 = 8_000_000_000

    static func recognize(
        in image: CGImage,
        usesLanguageCorrection: Bool
    ) async throws -> [VisionRecognizedText] {
        try Task.checkCancellation()
        try await coordinator.begin()

        let input = RecognitionInput(
            image: image,
            usesLanguageCorrection: usesLanguageCorrection
        )
        let completion = RecognitionCompletion<[VisionRecognizedText]>()

        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                completion.install(continuation)

                Task.detached(priority: .utility) {
                    let result: Result<[VisionRecognizedText], Error>
                    do {
                        try input.handler.perform([input.request])
                        result = .success(
                            (input.request.results ?? []).compactMap { observation in
                                guard let candidate = observation.topCandidates(1).first else {
                                    return nil
                                }
                                return VisionRecognizedText(
                                    text: candidate.string,
                                    confidence: candidate.confidence,
                                    boundingBox: observation.boundingBox
                                )
                            }
                        )
                    } catch {
                        result = .failure(error)
                    }

                    await coordinator.finish()
                    _ = completion.complete(with: result)
                }

                Task.detached(priority: .utility) {
                    try? await Task.sleep(nanoseconds: timeoutNanoseconds)
                    if completion.complete(with: .failure(VisionTextRecognitionError.timedOut)) {
                        input.request.cancel()
                    }
                }
            }
        } onCancel: {
            if completion.complete(with: .failure(CancellationError())) {
                input.request.cancel()
            }
        }
    }
}

/// Vision request objects and CGImage are safe to hand to one dedicated worker for the duration of
/// a recognition call, but do not declare Sendable conformance in every supported SDK.
private final class RecognitionInput: @unchecked Sendable {
    let request: VNRecognizeTextRequest
    let handler: VNImageRequestHandler

    init(image: CGImage, usesLanguageCorrection: Bool) {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = usesLanguageCorrection
        self.request = request
        self.handler = VNImageRequestHandler(cgImage: image, options: [:])
    }
}

/// Races native completion, timeout, and Swift-task cancellation while guaranteeing that the
/// checked continuation is resumed exactly once.
private final class RecognitionCompletion<Value>: @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<Value, Error>?
    private var pendingResult: Result<Value, Error>?
    private var isComplete = false

    func install(_ continuation: CheckedContinuation<Value, Error>) {
        lock.lock()
        if let pendingResult {
            lock.unlock()
            continuation.resume(with: pendingResult)
            return
        }
        self.continuation = continuation
        lock.unlock()
    }

    /// Returns true only for the result that won the race.
    func complete(with result: Result<Value, Error>) -> Bool {
        lock.lock()
        guard !isComplete else {
            lock.unlock()
            return false
        }
        isComplete = true
        if let continuation {
            self.continuation = nil
            lock.unlock()
            continuation.resume(with: result)
        } else {
            pendingResult = result
            lock.unlock()
        }
        return true
    }
}
