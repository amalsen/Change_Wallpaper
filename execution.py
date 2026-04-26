import sys
import subprocess
import json

json_variable_file = "variables.json"

with open(json_variable_file, "r") as f:
    json_data = json.load(f)

json_ps_script_path = json_data["ps_script_path"]
json_image = json_data["src"]["Directory"] + json_data["src"]["image"]
json_targetLocation = json_data["target"]["Disk"] + json_data["target"]["Directory"]

get_execution = "Get-ExecutionPolicy"
execution_test = subprocess.getoutput(["powershell", get_execution])

def execution(command):
    if execution_test.upper() != "REMOTESIGNED":
        subprocess.run(["powershell", command])

execution_remotesign = "Set-ExecutionPolicy RemoteSigned"
execution_revert = f"Set-ExecutionPolicy {execution_test}"

invalid_input_yn = "\nInvalid input. Type 'Y' or 'N'.\n"

print(f"\nCurrent values in '{json_variable_file}':\nPowerShell script (loacation and name): {json_ps_script_path}\nWallpaper (location and name): {json_image}\nTarget disk and location for wallpaper: {json_targetLocation}\n\n")

while True:
    json_variable = input(f"Are these variables correct from '{json_variable_file}'? (Y/N): ")
    json_variable = json_variable.upper()
    if json_variable == "Y":
        break
    elif json_variable == "N":
        print(f"\nAborted!\n\nEdit values in '{json_variable_file}' before running.\n")
        sys.exit()
    else:
        print(invalid_input_yn)

while True:
    execute = input("Do you wish to change the wallpaper? (Y/N): ")
    execute = execute.replace(" ", "")
    if execute.upper() == "Y":
        print("\nChanging wallpaper.")
        print(f"Current execution policy: {execution_test}")
        execution(execution_remotesign)
        temporary_execution = subprocess.getoutput(["powershell", get_execution])
        print(f"Temporary execution policy: {temporary_execution}\n")
        
        print("Running " + json_ps_script_path + ".")
        subprocess.run(["powershell", json_ps_script_path])

        execution(execution_revert)
        reverted_execution = subprocess.getoutput(["powershell", get_execution])
        print(f"\nReverted execution policy: {reverted_execution}")
        #subprocess.run(["powershell", "gpupdate /force"])
        print("\nEnjoy the new wallpaper :)\n")
        break
    elif execute.upper() == "N":
        print("\nAborted!\n")
        sys.exit()
    else:
        print(invalid_input_yn)

try:
    print("\nCode is finised running.")
    raise KeyboardInterrupt
except KeyboardInterrupt:
    input("Press Enter to exit...")