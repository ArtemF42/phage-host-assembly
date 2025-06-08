import os
import sys


def get_samples(config: dict) -> list[str]:
    samples = config.get('samples')

    if samples:
        if os.path.isfile(samples):
            with open(samples) as file:
                return [line for line in map(lambda line: line.strip(), file) if line]
        else:
            return samples.strip().split(',')
    else:
        sys.exit('The "samples" argument must be specified.')
