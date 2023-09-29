#!/bin/bash

echo "Now your validator is going move to MEV?"
echo "Do you want to proceed? (yes/no)"

read answer

if [ "$answer" == "yes" ]; then
  # Script commands go here
    echo "Script execution has started."

    echo "Please choose the closest location to your validator:"
    echo "1) Amsterdam"
    echo "2) Frankfurt"
    echo "3) New York"
    echo "4) Tokyo"
    read location

    if [ $location -eq 1 ]; then
        BLOCK_ENGINE_URL=https://amsterdam.mainnet.block-engine.jito.wtf
        RELAYER_URL=http://amsterdam.mainnet.relayer.jito.wtf:8100
        SHRED_RECEIVER_ADDR=74.118.140.240:1002
    elif [ $location -eq 2 ]; then
        BLOCK_ENGINE_URL=https://frankfurt.mainnet.block-engine.jito.wtf
        RELAYER_URL=http://frankfurt.mainnet.relayer.jito.wtf:8100
        SHRED_RECEIVER_ADDR=145.40.93.84:1002
    elif [ $location -eq 3 ]; then
        BLOCK_ENGINE_URL=https://ny.mainnet.block-engine.jito.wtf
        RELAYER_URL=http://ny.mainnet.relayer.jito.wtf:8100
        SHRED_RECEIVER_ADDR=141.98.216.96:1002
    elif [ $location -eq 4 ]; then
        BLOCK_ENGINE_URL=https://tokyo.mainnet.block-engine.jito.wtf
        RELAYER_URL=http://tokyo.mainnet.relayer.jito.wtf:8100
        SHRED_RECEIVER_ADDR=202.8.9.160:1002
    else
    echo "Invalid selection. Exiting."
    exit 1
    
    fi

    # Update packages
    sudo apt-get update

    # Install dependencies
    echo "Version tag: v1.13.6-jito"
    TAG="1.16.14-jito"

    curl https://sh.rustup.rs -sSf | sh
    source $HOME/.cargo/env
    rustup component add rustfmt
    rustup update
    sudo apt-get update
    sudo apt-get install libssl-dev libudev-dev pkg-config zlib1g-dev llvm clang cmake make libprotobuf-dev protobuf-compiler

    # Clone Jito Solana repository
    git clone https://github.com/jito-foundation/jito-solana.git

    cd jito-solana
    git pull
    git checkout tags/$TAG
    git submodule update --init --recursive
    CI_COMMIT=$(git rev-parse HEAD) scripts/cargo-install-all.sh ~/.local/share/solana/install/releases/"$TAG"

    echo "Want to change service file? (yes/no)"
    read answerd

    if [ "$answerd" == "yes" ]; then
        echo "Enter the service name of your validator:"
        read service_name
    
        # Stop the service
        sudo systemctl stop $service_name.service
    
        # Backup the service
        sudo cp /etc/systemd/system/$service_name.service /etc/systemd/system/${service_name}1.service
    
        # Replace the ExecStart line in the service file
        file=/etc/systemd/system/${service_name}.service
    
        if [ -f "$file" ]; then
            sudo sed -i 's|ExecStart.*|ExecStart='"$HOME"'/.local/share/solana/install/releases/'"$TAG"'/bin/solana-validator \\\n--tip-payment-program-pubkey T1pyyaTNZsKv2WcRAB8oVnk93mLJw2XzjtVYqCsaHqt \\\n--tip-distribution-program-pubkey 4R3gSG8BpU4t19KYj8CfnbtRpnT8gtk4dvTHxVRwc2r7 \\\n--merkle-root-upload-authority GZctHpWXmsZC1YHACTGGcHhYxjdRqQvTpYkb9LMvxDib \\\n--commission-bps 800 \\\n--relayer-url '"${RELAYER_URL}"' \\\n--block-engine-url '"${BLOCK_ENGINE_URL}"' \\\n--shred-receiver-address '"${SHRED_RECEIVER_ADDR}"' \\|g' "$file"
            echo "The ExecStart line in $file has been successfully modified."
        else
            echo "$file not found."
        fi
    else
        echo "No changes will be made to the service file."

    sudo systemctl daemon-reload
    sudo systemctl restart solana-validator
    echo "Script execution has been cancelled."
