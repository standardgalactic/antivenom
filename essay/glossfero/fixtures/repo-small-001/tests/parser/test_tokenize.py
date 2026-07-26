from src.parser import tokenize

def test_tokenize():
    assert len(tokenize("hello world")) == 2

def test_tokenize_empty():
    from src.parser import tokenize
    assert tokenize("") == []
