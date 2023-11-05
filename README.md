# Linux voice typing

## Install

```bash
sudo apt install xdotool jq curl arecord killall -y
```

you will need to set up an openAI key and put it in the `${HOME}/.openai-token` file

```txt
TOKEN=xxxxx
```

you will need to select a device to record from, you can find the device name with:

```bash
arecord -l
```


## Usage

Start the recording:

```bash
./voice-typing.sh
```

stop the recording writing the text you spoke to your current cursor position:
```bash
./voice-typing.sh
```
