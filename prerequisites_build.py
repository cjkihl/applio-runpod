import os
import sys

sys.path.insert(0, os.getcwd())

from rvc.lib.tools.prerequisites_download import prequisites_download_pipeline

prequisites_download_pipeline(pretraineds_hifigan=True, models=True, exe=False)
print("All prerequisites downloaded successfully.")
