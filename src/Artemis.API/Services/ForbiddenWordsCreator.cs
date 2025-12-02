using Artemis.API.Entities;
using Artemis.API.Infrastructure;
using Microsoft.EntityFrameworkCore;

namespace Artemis.API.Services;

public class ForbiddenWordsCreator
{
    private readonly ArtemisDbContext _artemisDbContext;

    public ForbiddenWordsCreator(ArtemisDbContext artemisDbContext)
    {
        _artemisDbContext = artemisDbContext;
    }

    private readonly Dictionary<char, char[]> CharMap = new()
    {
        { 'a', new []{'a','e','4'} },
        { 'b', new []{'b','8'} },
        { 'e', new []{'e','3'} },
        { 'g', new []{'g','9'} },
        { 'i', new []{'i','1','ı'} },
        { 'ı', new []{'ı','i'} },
        { 'o', new []{'o','0'} },
        { 's', new []{'s','$','5'} },
        { 't', new []{'t','7'} },
        { 'k', new []{'k','q'} }
    };

    private readonly char[] Symbols = { '.', '-', '_', '*', '!', '\'' };
    public HashSet<string> ExpandList(IEnumerable<string> words)
    {
        var finalSet = new HashSet<string>(StringComparer.OrdinalIgnoreCase);

        foreach (var w in words)
        {
            if (string.IsNullOrWhiteSpace(w)) continue;

            foreach (var item in ExpandWord(w))
            {
                finalSet.Add(item);
            }
        }

        return finalSet;
    }

    private HashSet<string> ExpandWord(string word)
    {
        var results = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
        {
            word,
            word.ToLower(),
            word.ToUpper(),
            Capitalize(word)
        };

        GenerateLetterVariants(word, results);
        GenerateDoubleLetters(word, results);
        GenerateMissingLetters(word, results);
        GenerateAddedLetters(word, results);
        GenerateSymbolMix(word, results);

        return results;
    }

    private void GenerateLetterVariants(string word, HashSet<string> set)
    {
        void DFS(char[] arr, int index)
        {
            if (index == arr.Length)
            {
                set.Add(new string(arr));
                return;
            }

            char key = char.ToLower(arr[index]);

            if (CharMap.ContainsKey(key))
            {
                foreach (var v in CharMap[key])
                {
                    var clone = (char[])arr.Clone();
                    clone[index] = v;
                    DFS(clone, index + 1);
                }
            }
            else
            {
                DFS(arr, index + 1);
            }
        }

        DFS(word.ToCharArray(), 0);
    }

    private void GenerateDoubleLetters(string word, HashSet<string> set)
    {
        for (int i = 0; i < word.Length; i++)
        {
            set.Add(word[..i] + new string(word[i], 2) + word[(i + 1)..]);
        }
    }

    private void GenerateMissingLetters(string word, HashSet<string> set)
    {
        for (int i = 0; i < word.Length; i++)
        {
            set.Add(word.Remove(i, 1));
        }
    }

    private void GenerateAddedLetters(string word, HashSet<string> set)
    {
        for (int i = 0; i < word.Length; i++)
        {
            set.Add(word.Insert(i, word[i].ToString()));
        }
    }

    private void GenerateSymbolMix(string word, HashSet<string> set)
    {
        foreach (var s in Symbols)
        {
            if (word.Length > 1)
            {
                set.Add($"{word[0]}{s}{word[1..]}");
                set.Add($"{word[..^1]}{s}{word[^1]}");
            }
        }
    }

    private string Capitalize(string word)
    {
        if (string.IsNullOrEmpty(word)) return word;
        return char.ToUpper(word[0]) + word[1..].ToLower();
    }

    public async Task SaveExpandedForbiddenWordsAsync(List<string> inputWords)
    {
        try
        {            
            var expanded = ExpandList(inputWords);

            var existingWords = await _artemisDbContext.ForbiddenWords
                .Select(x => x.Word.ToLower())
                .ToListAsync();
            
            var existingWordsSet = new HashSet<string>(existingWords, StringComparer.OrdinalIgnoreCase);

            var toInsert = new List<ForbiddenWord>();

            foreach (var word in expanded)
            {
                if (!existingWordsSet.Contains(word))
                {
                    toInsert.Add(new ForbiddenWord
                    {
                        Word = word
                    });
                }
            }


            if (toInsert.Count != 0)
            {
                await _artemisDbContext.ForbiddenWords.AddRangeAsync(toInsert);
                var savedCount = await _artemisDbContext.SaveChangesAsync();
            }
            else
            {
                // No new words to insert
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"ExceptionMessage: {ex.Message}");
            throw;
        }
    }
}