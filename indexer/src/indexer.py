#!/usr/bin/env python3
"""
RAG Document Indexer for GitHub Copilot Orchestra

This indexer processes documentation files and creates embeddings for RAG-based retrieval.
It supports markdown files and stores embeddings in a ChromaDB vector store.
"""

import os
import sys
from pathlib import Path
from typing import List, Optional

from dotenv import load_dotenv
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain_community.document_loaders import DirectoryLoader, TextLoader
from langchain_community.embeddings import OpenAIEmbeddings
from langchain_community.vectorstores import Chroma

# Load environment variables
load_dotenv()


class DocumentIndexer:
    """Handles document loading, chunking, and indexing for RAG."""

    def __init__(
        self,
        docs_dir: str,
        persist_dir: str,
        collection_name: str,
        chunk_size: int = 1000,
        chunk_overlap: int = 200,
        embedding_model: str = "text-embedding-3-small"
    ):
        """
        Initialize the document indexer.

        Args:
            docs_dir: Directory containing documents to index
            persist_dir: Directory to persist the vector store
            collection_name: Name of the collection in the vector store
            chunk_size: Size of text chunks for processing
            chunk_overlap: Overlap between chunks
            embedding_model: OpenAI embedding model to use
        """
        self.docs_dir = Path(docs_dir)
        self.persist_dir = persist_dir
        self.collection_name = collection_name
        self.chunk_size = chunk_size
        self.chunk_overlap = chunk_overlap
        
        # Initialize embeddings
        self.embeddings = OpenAIEmbeddings(model=embedding_model)
        
        # Initialize text splitter
        self.text_splitter = RecursiveCharacterTextSplitter(
            chunk_size=chunk_size,
            chunk_overlap=chunk_overlap,
            length_function=len,
            separators=["\n\n", "\n", " ", ""]
        )

    def load_documents(self) -> List:
        """
        Load documents from the specified directory.

        Returns:
            List of loaded documents
        """
        print(f"Loading documents from {self.docs_dir}...")
        
        # Load markdown files
        loader = DirectoryLoader(
            str(self.docs_dir),
            glob="**/*.md",
            loader_cls=TextLoader,
            show_progress=True,
            use_multithreading=True
        )
        
        documents = loader.load()
        print(f"Loaded {len(documents)} documents")
        
        return documents

    def chunk_documents(self, documents: List) -> List:
        """
        Split documents into chunks.

        Args:
            documents: List of documents to chunk

        Returns:
            List of document chunks
        """
        print(f"Chunking documents (size={self.chunk_size}, overlap={self.chunk_overlap})...")
        chunks = self.text_splitter.split_documents(documents)
        print(f"Created {len(chunks)} chunks")
        
        return chunks

    def create_index(self, chunks: List) -> Chroma:
        """
        Create or update the vector store index.

        Args:
            chunks: List of document chunks to index

        Returns:
            Chroma vector store instance
        """
        print(f"Creating vector store at {self.persist_dir}...")
        
        # Create vector store
        vectorstore = Chroma.from_documents(
            documents=chunks,
            embedding=self.embeddings,
            persist_directory=self.persist_dir,
            collection_name=self.collection_name
        )
        
        print(f"Index created with {len(chunks)} chunks")
        
        return vectorstore

    def run(self) -> Chroma:
        """
        Run the complete indexing pipeline.

        Returns:
            Chroma vector store instance
        """
        print("=" * 60)
        print("Starting Document Indexing Pipeline")
        print("=" * 60)
        
        # Step 1: Load documents
        documents = self.load_documents()
        
        if not documents:
            print("No documents found to index!")
            sys.exit(1)
        
        # Step 2: Chunk documents
        chunks = self.chunk_documents(documents)
        
        # Step 3: Create index
        vectorstore = self.create_index(chunks)
        
        print("=" * 60)
        print("Indexing completed successfully!")
        print("=" * 60)
        
        return vectorstore


def main():
    """Main entry point for the indexer."""
    # Get configuration from environment
    docs_dir = os.getenv("DOCS_DIR", "../docs")
    persist_dir = os.getenv("CHROMA_PERSIST_DIR", "./chroma_db")
    collection_name = os.getenv("COLLECTION_NAME", "copilot_orchestra_docs")
    chunk_size = int(os.getenv("CHUNK_SIZE", "1000"))
    chunk_overlap = int(os.getenv("CHUNK_OVERLAP", "200"))
    embedding_model = os.getenv("EMBEDDING_MODEL", "text-embedding-3-small")
    
    # Validate OpenAI API key
    if not os.getenv("OPENAI_API_KEY"):
        print("ERROR: OPENAI_API_KEY environment variable is not set!")
        print("Please set it in your .env file or as an environment variable.")
        sys.exit(1)
    
    # Create indexer
    indexer = DocumentIndexer(
        docs_dir=docs_dir,
        persist_dir=persist_dir,
        collection_name=collection_name,
        chunk_size=chunk_size,
        chunk_overlap=chunk_overlap,
        embedding_model=embedding_model
    )
    
    # Run indexing
    try:
        indexer.run()
    except Exception as e:
        print(f"ERROR: Indexing failed: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
