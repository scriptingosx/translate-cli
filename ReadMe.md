# macOS translate CLI

macOS command line tool to translate input using the built-in macOS Translation Service.

## What it does

macOS 26 has a fairly robust [built-in Translation service](https://support.apple.com/guide/mac-help/translate-text-on-mac-mchldd8b3c15/mac).

This command line tool uses the Translation service to translate text passed as arguments from one language to another using Apple's Translation framework.

## Requirements
This tool requires macOS 26.0.

## Installation

You can build the package from source with

```sh
swift build -c release
```

or use [the pkg installer available in releases](/latest/releases).

## Usage

**Important:** You have to download the Translation resources in System Settings > Languge & Region > Translation Languages… (button at the bottom of that pane) _before_ using this tool. Otherwise you will get `Error: Unable to Translate` messages. You only need to download the languages you are going to use.

### Translation

By default, `translate` will translate the text from the arguments to the _current system language_. (in the examples, the current system language is English)

```sh
$ translate "Dies ist ein kurzer Satz."
This is a short sentence.
```

Multiple arguments will be joined together, so you don't need to quote the input, unless there are special characters:

```sh
$ translate Dies ist ein kurzer Satz.
This is a short sentence.
```

```sh
$ translate "Dies ist ein kurzer Satz!"
This is a short sentence.
```

You can set different target languages with the `--to` flag:

```sh
$ translate "Dies ist ein kurzer Satz." --to fr
C'est une courte phrase.
```

You can provide multiple `--to` options with different language codes. Each translation will be prepended with the language code.

```sh
$ translate --to en --to fr --to es "Dies ist ein kurzer Satz."
en: This is a short sentence.
fr: C'est une courte phrase.
es: Esta es una frase corta.
```

The source language will be determined from the text. You can override the detection with the `--from` flag:

```sh
$ translate --from de "Dies ist ein kurzer Satz."
This is a short sentence.
$ translate --from de --to fr "Dies ist ein kurzer Satz."
C'est une courte phrase.
```

When no arguments are given as arguments, text will be read from standard input:

```sh
$ echo "Dies ist ein kurzer Satz." | translate
This is a short sentence.
```

### Language detection

When you add the `--detect` flag, the detected source language code will be printed:

```sh
$ translate --detect "Dies ist ein kurzer Satz."
de
```


