#!/usr/bin/env python3

import os
import sys
import json
import argparse

from jinja2 import Environment, FileSystemLoader, select_autoescape


def parse_args():
    parser = argparse.ArgumentParser(
        prog='parse_template',
        description='a jinja template parser',
        add_help=False
    )

    parser.add_argument(
        '-h', '--help',
        action='help',
        help='display help message',
    )

    parser.add_argument(
        '-D', '--define',
        action='append',
        nargs=2,
        type=str,
        metavar=('key', 'value'),
        help='define data with key-value pairs',
    )

    parser.add_argument(
        '-o', '--output',
        nargs='?',
        type=str,
        metavar='file',
        help='output file or "-" for stdout',
    )

    parser.add_argument(
        'docdir',
        type=str,
        metavar='docdir',
        help='Full documentation directory path',
    )

    parser.add_argument(
        'template',
        type=str,
        metavar='template',
        help='template file path relative to docdir',
    )

    return parser.parse_args()


def parse_value(value):
    try:
        return json.loads(value)
    except ValueError:
        return value


def main():
    args = parse_args()

    doc_dir = args.docdir
    template_path = args.template
    output = args.output or os.path.join(doc_dir, template_path)
    data = {k: parse_value(v) for k, v in args.define or []}

    env = Environment(
        loader=FileSystemLoader(doc_dir),
        autoescape=False,
        block_start_string='<!-- {%',
        block_end_string='%} -->',
        variable_start_string='<!-- {{',
        variable_end_string='}} -->',
        comment_start_string='<!-- {#',
        comment_end_string='#} -->',
        auto_reload=True,
        trim_blocks=True,
        lstrip_blocks=True
    )
    template = env.get_template(template_path)

    if output == '-':
        print(template.render(**data))
    else:
        fout = open(output, 'w')
        try:
            fout.write(template.render(**data))
        finally:
            fout.close()


if __name__ == '__main__':
    main()

