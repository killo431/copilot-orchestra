#!/usr/bin/env python3
"""
Basic tests for the document indexer.
"""

import os
import sys
import tempfile
from pathlib import Path

# Add src to path
sys.path.insert(0, str(Path(__file__).parent.parent / "src"))

from indexer import DocumentIndexer


def test_initialization():
    """Test that indexer initializes correctly."""
    print("Testing initialization...")
    
    with tempfile.TemporaryDirectory() as tmpdir:
        indexer = DocumentIndexer(
            docs_dir=tmpdir,
            persist_dir=tmpdir,
            collection_name="test_collection"
        )
        
        assert indexer.chunk_size == 1000
        assert indexer.chunk_overlap == 200
        assert indexer.collection_name == "test_collection"
    
    print("✓ Initialization test passed")


def test_document_loading():
    """Test document loading with sample markdown files."""
    print("Testing document loading...")
    
    with tempfile.TemporaryDirectory() as tmpdir:
        # Create sample markdown files
        test_doc = Path(tmpdir) / "test.md"
        test_doc.write_text("# Test Document\n\nThis is a test document.")
        
        indexer = DocumentIndexer(
            docs_dir=tmpdir,
            persist_dir=tmpdir,
            collection_name="test_collection"
        )
        
        documents = indexer.load_documents()
        assert len(documents) > 0
        assert "Test Document" in documents[0].page_content
    
    print("✓ Document loading test passed")


def test_chunking():
    """Test document chunking."""
    print("Testing document chunking...")
    
    with tempfile.TemporaryDirectory() as tmpdir:
        # Create a larger document
        content = "# Test\n\n" + ("This is a test paragraph. " * 100)
        test_doc = Path(tmpdir) / "test.md"
        test_doc.write_text(content)
        
        indexer = DocumentIndexer(
            docs_dir=tmpdir,
            persist_dir=tmpdir,
            collection_name="test_collection",
            chunk_size=500,
            chunk_overlap=50
        )
        
        documents = indexer.load_documents()
        chunks = indexer.chunk_documents(documents)
        
        assert len(chunks) > 1
        print(f"  Created {len(chunks)} chunks from document")
    
    print("✓ Chunking test passed")


def main():
    """Run all tests."""
    print("=" * 60)
    print("Running Indexer Tests")
    print("=" * 60)
    
    try:
        test_initialization()
        test_document_loading()
        test_chunking()
        
        print("\n" + "=" * 60)
        print("All tests passed! ✓")
        print("=" * 60)
        return 0
        
    except Exception as e:
        print(f"\n✗ Test failed: {e}")
        import traceback
        traceback.print_exc()
        return 1


if __name__ == "__main__":
    sys.exit(main())
