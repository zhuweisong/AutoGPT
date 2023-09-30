import ast
import pytest

from forge.agent import parse_command_using_ast


# Unit tests
def test_parse_command_using_ast():
    # Test with given input
    input_str = 'example("my_gift.txt", "I would suggest her to buy her flowers")'
    expected_output = {
        'command': 'example',
        'arg_1': 'my_gift.txt',
        'arg_2': 'I would suggest her to buy her flowers'
    }
    assert parse_command_using_ast(input_str) == expected_output

    # Test with multiple arguments
    input_str = 'example("arg1", "arg2", "arg3", "arg4")'
    expected_output = {
        'command': 'example',
        'arg_1': 'arg1',
        'arg_2': 'arg2',
        'arg_3': 'arg3',
        'arg_4': 'arg4'
    }
    assert parse_command_using_ast(input_str) == expected_output

    # Test with no arguments
    input_str = 'example()'
    expected_output = {
        'command': 'example'
    }
    assert parse_command_using_ast(input_str) == expected_output

    # Test with non-string argument (shouldn't be included in result)
    input_str = 'example("arg1", 123)'
    expected_output = {
        'command': 'example',
        'arg_1': 'arg1'
    }
    assert parse_command_using_ast(input_str) == expected_output

    # Test with malformed code
    input_str = 'example(("arg1")'
    assert parse_command_using_ast(input_str) == None
