//
//  StringSlangNormalizationTests.swift
//  SlangTranslatorTests
//
//  Tests for String+SlangNormalization extension.
//

import Testing
import Foundation
@testable import SLNG

struct StringSlangNormalizationTests {

    // MARK: - normalizedForSlangMatching Tests

    @Test func normalizedForSlangMatching_lowercasesString() async throws {
        #expect("HELLO".normalizedForSlangMatching() == "helo")
        #expect("WoRlD".normalizedForSlangMatching() == "world")
    }

    @Test func normalizedForSlangMatching_collapsesRepeatedCharacters() async throws {
        #expect("hellooo".normalizedForSlangMatching() == "helo")
        #expect("woooow".normalizedForSlangMatching() == "wow")
        #expect("yessss".normalizedForSlangMatching() == "yes")
        #expect("noooope".normalizedForSlangMatching() == "nope")
    }

    @Test func normalizedForSlangMatching_handlesMixedRepetitions() async throws {
        #expect("heeeellooo".normalizedForSlangMatching() == "helo")
        #expect("whaaat".normalizedForSlangMatching() == "what")
        #expect("coooool".normalizedForSlangMatching() == "col")
    }

    @Test func normalizedForSlangMatching_preservesNonRepeatedCharacters() async throws {
        #expect("hello".normalizedForSlangMatching() == "helo")
        #expect("world".normalizedForSlangMatching() == "world")
        #expect("test".normalizedForSlangMatching() == "test")
    }

    @Test func normalizedForSlangMatching_handlesEmptyString() async throws {
        #expect("".normalizedForSlangMatching() == "")
    }

    @Test func normalizedForSlangMatching_handlesSingleCharacter() async throws {
        #expect("a".normalizedForSlangMatching() == "a")
        #expect("A".normalizedForSlangMatching() == "a")
    }

    @Test func normalizedForSlangMatching_handlesRepeatedSingleCharacter() async throws {
        #expect("aaaa".normalizedForSlangMatching() == "a")
        #expect("BBBB".normalizedForSlangMatching() == "b")
    }

    @Test func normalizedForSlangMatching_handlesIndonesianSlang() async throws {
        // Common Indonesian slang patterns
        #expect("woyyy".normalizedForSlangMatching() == "woy")
        #expect("banggg".normalizedForSlangMatching() == "bang")
        #expect("gaesss".normalizedForSlangMatching() == "gaes")
        #expect("asikkk".normalizedForSlangMatching() == "asik")
    }

    // MARK: - maxRepeatRun Tests

    @Test func maxRepeatRun_noRepeats_returnsOne() async throws {
        #expect("hello".maxRepeatRun() == 2) // 'll' is 2
        #expect("world".maxRepeatRun() == 1)
        #expect("abc".maxRepeatRun() == 1)
    }

    @Test func maxRepeatRun_withRepeats_returnsMaxCount() async throws {
        #expect("hellooo".maxRepeatRun() == 3) // 'ooo' is 3
        #expect("wooooow".maxRepeatRun() == 5) // 'ooooo' is 5
        #expect("yeeeees".maxRepeatRun() == 5) // 'eeeee' is 5
    }

    @Test func maxRepeatRun_multipleRepeatGroups_returnsMax() async throws {
        #expect("heeellooo".maxRepeatRun() == 3) // both 'eee' and 'ooo' are 3
        #expect("aaabbbbb".maxRepeatRun() == 5) // 'bbbbb' is 5
    }

    @Test func maxRepeatRun_caseInsensitive() async throws {
        #expect("HELLO".maxRepeatRun() == 2) // 'LL' becomes 'll'
        #expect("HeLLo".maxRepeatRun() == 2)
    }

    @Test func maxRepeatRun_emptyString_returnsOne() async throws {
        // Based on the implementation, empty string returns maxRun of 1 (initial value)
        #expect("".maxRepeatRun() == 1)
    }

    @Test func maxRepeatRun_singleCharacter_returnsOne() async throws {
        #expect("a".maxRepeatRun() == 1)
        #expect("Z".maxRepeatRun() == 1)
    }

    @Test func maxRepeatRun_allSameCharacter_returnsLength() async throws {
        #expect("aaa".maxRepeatRun() == 3)
        #expect("bbbbb".maxRepeatRun() == 5)
    }

    // MARK: - Edge Cases

    @Test func normalizedForSlangMatching_withNumbers() async throws {
        #expect("test123".normalizedForSlangMatching() == "test123")
        #expect("111aaa".normalizedForSlangMatching() == "1a")
    }

    @Test func normalizedForSlangMatching_withSpaces() async throws {
        #expect("hello world".normalizedForSlangMatching() == "helo world")
        #expect("heeeey   you".normalizedForSlangMatching() == "hey   you")
    }

    @Test func normalizedForSlangMatching_withSpecialCharacters() async throws {
        #expect("hello!".normalizedForSlangMatching() == "helo!")
        #expect("wow???".normalizedForSlangMatching() == "wow?")
    }
}
