# BugleNews

A native iOS news reader built with **UIKit** (programmatic layout) and the **VIPER** architecture, powered by the [News API](https://newsapi.org/).

## Features

- **Category Browsing (`CategoryList`):** Browse news categories and select a category to view available sources.
- **Source Discovery & Search (`SourceList`):** View news outlets for a selected category, filter sources with live search, retry on errors, and open a source's articles.
- **Article Feed, Search & Pagination (`ArticleList`):** Read headlines from a selected news source with search filtering, automatic pagination as you scroll, error handling/retries, and detail navigation.
- **Article Reader (`ArticleDetail`):** Validate article URLs, load article pages with loading/error states, and retry when needed.

## Architecture

BugleNews follows **VIPER** across four modular features:

- `CategoryList`
- `SourceList`
- `ArticleList`
- `ArticleDetail`

Each module separates View (`ViewSpecs`), Presenter (`PresenterSpecs`), Interactor (`InteractorInputSpecs` / `InteractorOutputSpecs`), Router (`RouterSpecs`), and state/model types.

## Requirements

- Xcode with iOS SDK support
- Swift
- A News API key

## Setup & Configuration

1. Clone the repository:
   ```
   git clone https://github.com/arnoldp4/BugleNews.git
   cd BugleNews
   ```
2. Configure your API key (Config.plist is ignored so secrets stay out of version control):
   - Copy Config.example.plist to Config.plist with your News API key.
3. Open the project in Xcode, select a simulator, and run (Cmd + R).

## Testing

Unit tests cover presenters and interactors across the VIPER modules (CategoryList, SourceList, ArticleList, and ArticleDetail). 

Run the test suite in Xcode with Cmd + U.
