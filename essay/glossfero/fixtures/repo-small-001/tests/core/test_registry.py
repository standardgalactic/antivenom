from src.core.registry import Registry

def test_add():
    r = Registry()
    r.add("word", "hi")
    assert len(r.tokens) == 1
