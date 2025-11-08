# RAG Indexer Integration Guide

This guide explains the RAG (Retrieval Augmented Generation) indexer component that has been added to the GitHub Copilot Orchestra project.

## Overview

The RAG indexer creates searchable embeddings of the project documentation, enabling AI-powered semantic search and retrieval capabilities. This can be used to enhance AI assistants with project-specific knowledge.

## What is RAG?

Retrieval Augmented Generation (RAG) is a technique that enhances Large Language Models (LLMs) by providing them with relevant context retrieved from a knowledge base. The process involves:

1. **Indexing**: Documents are processed, chunked, and converted to embeddings
2. **Retrieval**: When a query is made, relevant document chunks are retrieved based on semantic similarity
3. **Generation**: The LLM generates responses using both its training and the retrieved context

## Architecture

```
Project Documentation
        ↓
   Document Loader
        ↓
   Text Chunking
        ↓
   OpenAI Embeddings
        ↓
   ChromaDB Vector Store
        ↓
   Semantic Search API
        ↓
   AI Assistant with Context
```

## Components

### Document Indexer

Located in `/indexer`, this component:

- **Loads** markdown documentation files
- **Chunks** documents into optimal sizes (1000 chars with 200 char overlap)
- **Generates** embeddings using OpenAI's text-embedding-3-small model
- **Stores** embeddings in a ChromaDB vector database
- **Persists** the vector store for reuse

### Key Features

1. **Automatic Documentation Discovery**
   - Recursively scans documentation directories
   - Processes all `.md` files
   - Includes project README, guides, and documentation

2. **Smart Chunking**
   - Splits documents at natural boundaries (paragraphs, sections)
   - Maintains context with configurable overlap
   - Optimizes chunk size for embedding quality

3. **Vector Storage**
   - Uses ChromaDB for efficient vector operations
   - Supports persistence across runs
   - Enables fast similarity search

4. **Docker Deployment**
   - Fully containerized
   - Easy to deploy and scale
   - Isolated dependencies

## Quick Start

### 1. Navigate to Indexer Directory

```bash
cd indexer
```

### 2. Configure Environment

```bash
cp .env.example .env
# Edit .env and add your OPENAI_API_KEY
```

### 3. Run Setup Script

```bash
./setup.sh
```

This will:
- Verify Docker installation
- Check configuration
- Build the Docker image
- Prepare the environment

### 4. Run the Indexer

```bash
docker compose up
```

The indexer will process all documentation and create the vector store at `indexer/chroma_db/`.

## Configuration

### Environment Variables

Configure the indexer via `.env` file:

```env
# Required
OPENAI_API_KEY=sk-your-key-here

# Optional (with defaults)
DOCS_DIR=../docs                          # Documentation directory
CHROMA_PERSIST_DIR=./chroma_db            # Vector store location
COLLECTION_NAME=copilot_orchestra_docs    # Collection name
CHUNK_SIZE=1000                           # Chunk size in characters
CHUNK_OVERLAP=200                         # Overlap between chunks
EMBEDDING_MODEL=text-embedding-3-small    # OpenAI model
```

### Customizing Document Sources

Edit `indexer/docker-compose.yml` to add more documentation sources:

```yaml
volumes:
  - ../docs:/app/docs:ro
  - ../README.md:/app/docs/README.md:ro
  - ../your-additional-docs:/app/docs/additional:ro
```

## Using the Vector Store

After indexing, you can query the vector store in your applications:

### Python Example

```python
from langchain_community.embeddings import OpenAIEmbeddings
from langchain_community.vectorstores import Chroma

# Initialize
embeddings = OpenAIEmbeddings(model="text-embedding-3-small")
vectorstore = Chroma(
    persist_directory="./indexer/chroma_db",
    embedding_function=embeddings,
    collection_name="copilot_orchestra_docs"
)

# Search
query = "How do I create a custom agent?"
results = vectorstore.similarity_search(query, k=3)

for doc in results:
    print(f"Source: {doc.metadata['source']}")
    print(f"Content: {doc.page_content}\n")
```

### JavaScript/TypeScript Example

```typescript
import { Chroma } from "@langchain/community/vectorstores/chroma";
import { OpenAIEmbeddings } from "@langchain/openai";

// Initialize
const embeddings = new OpenAIEmbeddings({
  modelName: "text-embedding-3-small",
});

const vectorStore = await Chroma.fromExistingCollection(embeddings, {
  collectionName: "copilot_orchestra_docs",
  url: "http://localhost:8000", // ChromaDB server
});

// Search
const results = await vectorStore.similaritySearch(
  "How do I create a custom agent?",
  3
);

results.forEach((doc) => {
  console.log(`Source: ${doc.metadata.source}`);
  console.log(`Content: ${doc.pageContent}\n`);
});
```

## Integration Scenarios

### 1. Custom Copilot Agent with RAG

Create an agent that uses the vector store to answer project-specific questions:

1. Query the vector store for relevant documentation
2. Pass the retrieved content as context to the agent
3. Agent generates response using both its knowledge and the documentation

### 2. Documentation Search API

Build a REST API for semantic documentation search:

```python
from fastapi import FastAPI
from pydantic import BaseModel

app = FastAPI()

class Query(BaseModel):
    question: str
    k: int = 3

@app.post("/search")
async def search_docs(query: Query):
    results = vectorstore.similarity_search(query.question, k=query.k)
    return {
        "results": [
            {
                "content": doc.page_content,
                "source": doc.metadata["source"]
            }
            for doc in results
        ]
    }
```

### 3. Interactive Documentation Assistant

Create a chat interface that uses RAG to answer questions:

1. User asks a question
2. System retrieves relevant documentation
3. LLM generates a response with citations
4. User can click through to source documents

## Maintenance

### Re-indexing Documentation

When documentation is updated:

```bash
cd indexer
rm -rf chroma_db/
docker compose up
```

### Monitoring Index Size

```bash
# Check vector store size
du -sh indexer/chroma_db/

# Check number of indexed documents
python -c "
from langchain_community.vectorstores import Chroma
from langchain_community.embeddings import OpenAIEmbeddings
vectorstore = Chroma(
    persist_directory='./indexer/chroma_db',
    embedding_function=OpenAIEmbeddings(),
    collection_name='copilot_orchestra_docs'
)
print(f'Total chunks: {vectorstore._collection.count()}')
"
```

### Backup and Restore

```bash
# Backup
tar -czf chroma_backup_$(date +%Y%m%d).tar.gz indexer/chroma_db/

# Restore
tar -xzf chroma_backup_YYYYMMDD.tar.gz
```

## Performance Tuning

### Chunk Size Optimization

- **Smaller chunks (500)**: Better for precise answers, more chunks to process
- **Larger chunks (1500)**: Better for comprehensive context, fewer chunks
- **Default (1000)**: Balanced approach for most use cases

### Embedding Model Selection

- **text-embedding-3-small**: Fast, cost-effective, good quality (default)
- **text-embedding-3-large**: Higher quality, slower, more expensive
- **text-embedding-ada-002**: Previous generation, still reliable

### Retrieval Parameters

```python
# Get more results for comprehensive answers
results = vectorstore.similarity_search(query, k=5)

# Use similarity score threshold
results = vectorstore.similarity_search_with_score(query, k=5)
filtered = [doc for doc, score in results if score > 0.7]
```

## Cost Considerations

### Indexing Costs

OpenAI embedding costs (as of 2024):
- **text-embedding-3-small**: $0.02 per 1M tokens
- **text-embedding-3-large**: $0.13 per 1M tokens

Typical project documentation (500K tokens): ~$0.01 with small model

### Query Costs

- Vector search in ChromaDB: Free (local computation)
- Embedding the query: ~$0.00001 per query
- LLM generation: Varies by model and response length

### Storage

- ChromaDB vector store: ~10-50 MB for typical documentation
- Scales linearly with documentation size

## Troubleshooting

### Common Issues

1. **No documents indexed**
   - Check `DOCS_DIR` path
   - Verify markdown files exist
   - Review Docker volume mounts

2. **OpenAI API errors**
   - Verify API key is correct
   - Check API quota and billing
   - Ensure network connectivity

3. **Build failures**
   - SSL certificate issues in sandboxed environments
   - Try local development setup instead
   - Check Docker and network configuration

4. **Slow indexing**
   - Reduce batch size
   - Use smaller embedding model
   - Process fewer documents at once

### Debug Mode

Enable verbose logging:

```python
import logging
logging.basicConfig(level=logging.DEBUG)
```

## Security Best Practices

1. **API Key Protection**
   - Never commit `.env` files
   - Use environment variables in production
   - Rotate keys periodically

2. **Access Control**
   - Restrict vector store access
   - Use authentication for search APIs
   - Implement rate limiting

3. **Data Privacy**
   - Be mindful of sensitive documentation
   - Consider on-premise embedding solutions
   - Review data retention policies

## Next Steps

1. **Integrate with Custom Agents**: Use the vector store in your custom Copilot agents
2. **Build Search API**: Create a REST API for documentation search
3. **Add Chat Interface**: Build an interactive documentation assistant
4. **Monitor Usage**: Track queries and improve documentation based on searches
5. **Expand Sources**: Index additional resources (code comments, issues, PRs)

## Resources

- [Indexer README](../indexer/README.md) - Detailed indexer documentation
- [LangChain RAG Guide](https://python.langchain.com/docs/use_cases/question_answering/)
- [ChromaDB Documentation](https://docs.trychroma.com/)
- [OpenAI Embeddings Guide](https://platform.openai.com/docs/guides/embeddings)

## Support

For issues or questions:
- Check the [Troubleshooting Guide](../TROUBLESHOOTING.md)
- Review [indexer/README.md](../indexer/README.md)
- Open an issue on GitHub
