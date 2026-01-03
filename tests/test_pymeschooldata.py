"""
Tests for pymeschooldata Python wrapper.

Minimal smoke tests - the actual data logic is tested by R testthat.
These just verify the Python wrapper imports and exposes expected functions.
"""

import pytest


def test_import_package():
    """Package imports successfully."""
    import pymeschooldata
    assert pymeschooldata is not None


def test_has_fetch_enr():
    """fetch_enr function is available."""
    import pymeschooldata
    assert hasattr(pymeschooldata, 'fetch_enr')
    assert callable(pymeschooldata.fetch_enr)


def test_has_get_available_years():
    """get_available_years function is available."""
    import pymeschooldata
    assert hasattr(pymeschooldata, 'get_available_years')
    assert callable(pymeschooldata.get_available_years)


def test_has_version():
    """Package has a version string."""
    import pymeschooldata
    assert hasattr(pymeschooldata, '__version__')
    assert isinstance(pymeschooldata.__version__, str)
