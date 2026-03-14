import numpy as np
import matplotlib.pyplot as plt

def infer_cache_line(strides, latency):

    diff = np.diff(latency)

    idx = np.argmax(diff)

    return strides[idx]


def plot_curve(strides, latency):

    plt.plot(strides, latency)
    plt.xscale("log")
    plt.xlabel("stride")
    plt.ylabel("latency")
    plt.show()