# RAG Document Indexer for GitHub Copilot Orchestra

A ready-to-deploy document indexer that creates embeddings for Retrieval Augmented Generation (RAG) applications. This indexer processes the GitHub Copilot Orchestra documentation and creates a searchable vector store using OpenAI embeddings and ChromaDB.

## Features

- 📄 **Markdown Document Processing** - Automatically loads and processes all markdown files
- 🔍 **Smart Chunking** - Splits documents into optimal chunks with configurable size and overlap
- 🚀 **OpenAI Embeddings** - Uses state-of-the-art text-embedding-3-small model
- 💾 **ChromaDB Vector Store** - Persists embeddings for fast retrieval
- 🐳 **Docker Ready** - Fully containerized for easy deployment
- ⚙️ **Configurable** - Extensive configuration options via environment variables

## Prerequisites

- Docker and Docker Compose v2 (for containerized deployment)
  - Docker Compose v2 uses `docker compose` command (not `docker-compose`)
- OR Python 3.11+ (for local development)
- OpenAI API Key

## Quick Start with Docker

### 1. Setup Environment

Create a `.env` file in the `indexer` directory:

```bash
cp .env.example .env
```

Edit `.env` and add your OpenAI API key:

```env
OPENAI_API_KEY=sk-your-api-key-here
```

### 2. Build and Run

```bash
# Build the Docker image
docker compose build

# Run the indexer
docker compose up
```

The indexer will:
1. Load all markdown files from the docs directory
2. Chunk them into optimal sizes
3. Generate embeddings using OpenAI
4. Store them in ChromaDB at `./chroma_db`

### 3. Verify

After successful indexing, you'll see:

```
============================================================
Indexing completed successfully!
============================================================
```

The vector store will be persisted in the `chroma_db` directory.

## Local Development

### 1. Install Dependencies

```bash
cd indexer
pip install -r requirements.txt
```

### 2. Setup Environment

```bash
cp .env.example .env
# Edit .env with your configuration
```

### 3. Run Indexer

```bash
python src/indexer.py
```

## Configuration

All configuration is done via environment variables. You can set these in:
- `.env` file (for local development)
- `docker-compose.yml` (for Docker deployment)
- System environment variables

### Available Options

| Variable | Default | Description |
|----------|---------|-------------|
| `OPENAI_API_KEY` | *required* | Your OpenAI API key |
| `DOCS_DIR` | `../docs` | Directory containing documents to index |
| `CHROMA_PERSIST_DIR` | `./chroma_db` | Directory to persist vector store |
| `COLLECTION_NAME` | `copilot_orchestra_docs` | Name of the vector store collection |
| `CHUNK_SIZE` | `1000` | Size of text chunks (in characters) |
| `CHUNK_OVERLAP` | `200` | Overlap between chunks |
| `EMBEDDING_MODEL` | `text-embedding-3-small` | OpenAI embedding model |

### Customizing Document Sources

To index different directories, update the `docker-compose.yml` volumes section:

```yaml
volumes:
  - /path/to/your/docs:/app/docs:ro
  - ./chroma_db:/app/chroma_db
```

## Architecture

```
┌─────────────────────┐
│  Document Loader    │
│  (Markdown files)   │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Text Splitter      │
│  (Chunking)         │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  OpenAI Embeddings  │
│  (text-embedding-3) │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  ChromaDB Store     │
│  (Vector DB)        │
└─────────────────────┘
```

## Project Structure

```
indexer/
├── Dockerfile              # Container definition
├── docker-compose.yml      # Docker Compose configuration
├── requirements.txt        # Python dependencies
├── .env.example           # Environment template
├── README.md              # This file
├── src/
│   └── indexer.py         # Main indexer application
├── tests/                 # Test files (future)
├── data/                  # Temporary data (gitignored)
└── chroma_db/            # Vector store (persisted)
```

## Usage with RAG Applications

After indexing, the vector store can be used in RAG applications:

```python
from langchain_community.embeddings import OpenAIEmbeddings
from langchain_community.vectorstores import Chroma

# Load the vector store
embeddings = OpenAIEmbeddings(model="text-embedding-3-small")
vectorstore = Chroma(
    persist_directory="./chroma_db",
    embedding_function=embeddings,
    collection_name="copilot_orchestra_docs"
)

# Query the store
results = vectorstore.similarity_search("How do I use the Conductor agent?", k=3)
for doc in results:
    print(doc.page_content)
```

## Troubleshooting

### No documents found

**Problem**: Indexer reports "No documents found to index!"

**Solution**: 
- Check that the `DOCS_DIR` path is correct
- Verify markdown files exist in the directory
- Check Docker volume mounts in `docker-compose.yml`

### OpenAI API Error

**Problem**: "OPENAI_API_KEY environment variable is not set"

**Solution**:
- Ensure `.env` file exists with `OPENAI_API_KEY=your-key`
- For Docker, check that docker-compose.yml reads from .env

### Permission Errors

**Problem**: Cannot write to `chroma_db` directory

**Solution**:
- Check directory permissions
- For Docker: ensure volume mount paths are correct

### SSL Certificate Errors During Build

**Problem**: SSL certificate verification errors when building Docker image in restricted environments

**Solution**:
- This may occur in sandboxed/corporate environments with SSL inspection
- Try building on a different network or machine
- Alternatively, use local development setup (see "Local Development" section)
- If necessary, update Dockerfile to handle SSL certificates for your environment

## Performance Considerations

- **Chunk Size**: Larger chunks (1000+) are better for context, smaller chunks (500-) for precision
- **Overlap**: 200 characters overlap helps maintain context across chunks
- **Batch Processing**: The indexer processes all files in one go; for large datasets, consider batching

## Cost Estimation

OpenAI embedding costs (as of 2024):
- **text-embedding-3-small**: $0.02 / 1M tokens
- Average documentation: ~500,000 tokens = ~$0.01

## Re-indexing

To re-index documents:

```bash
# Remove old vector store
rm -rf chroma_db/

# Run indexer again
docker compose up
```

## License

MIT License - See parent repository LICENSE file

## Related

- [GitHub Copilot Orchestra](../) - Parent project
- [LangChain Documentation](https://python.langchain.com/)
- [ChromaDB Documentation](https://docs.trychroma.com/)
- [OpenAI Embeddings](https://platform.openai.com/docs/guides/embeddings)
