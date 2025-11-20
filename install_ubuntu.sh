#!/usr/bin/env bash

set -e

echo "=== UAARG ArduPilot SITL Installer (Ubuntu) ==="

# --- Update ---
echo "[1/10] Updating apt..."
sudo apt-get update

# --- Base Packages ---
echo "[2/10] Installing git and utilities..."
sudo apt-get install -y git gitk git-gui curl python3-pip

# --- Clone ArduPilot ---
if [ ! -d "ardupilot" ]; then
  echo "[3/10] Cloning ArduPilot..."
  git clone --recurse-submodules https://github.com/ArduPilot/ardupilot.git
else
  echo "[3/10] ArduPilot directory already exists — skipping clone."
fi

cd ardupilot

# --- Install SITL dependencies ---
echo "[4/10] Installing SITL prerequisites..."
Tools/environment_install/install-prereqs-ubuntu.sh -y

echo "[5/10] Reloading PATH..."
. ~/.profile

# --- Build ArduPilot Copter ---
echo "[6/10] Building ArduCopter..."
./waf configure
./waf copter
./waf clean

cd ..

# --- Simulator Scripts ---
echo "[7/10] Cloning simulator-scripts..."
if [ ! -d "simulator-scripts" ]; then
  git clone https://github.com/uaarg/simulator-scripts.git
fi

echo "[8/10] Making scripts executable..."
chmod +x simulator-scripts/*.sh || true

# --- Install Gazebo Harmonic (Binary Install) ---
echo "[9/10] Installing Gazebo Harmonic..."
sudo apt-get install -y lsb-release wget gnupg

sudo wget https://packages.osrfoundation.org/gazebo.gpg -O /usr/share/keyrings/gazebo.gpg
echo "deb [signed-by=/usr/share/keyrings/gazebo.gpg] http://packages.osrfoundation.org/gazebo/ubuntu-stable \
$(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/gazebo-stable.list

sudo apt-get update
sudo apt-get install -y gz-harmonic

# --- Install ardupilot_gazebo ---
echo "[10/10] Installing ardupilot_gazebo plugin..."
if [ ! -d "ardupilot_gazebo" ]; then
  git clone https://github.com/ArduPilot/ardupilot_gazebo.git
fi

cd ardupilot_gazebo
mkdir -p build
cd build
cmake ..
make -j$(nproc)

cd ../..

echo "Adding Gazebo plugin paths to ~/.bashrc..."
echo "" >> ~/.bashrc
echo "# ArduPilot Gazebo Plugin Paths" >> ~/.bashrc
echo "export GZ_SIM_SYSTEM_PLUGIN_PATH=\$HOME/ardupilot_gazebo/build:\$GZ_SIM_SYSTEM_PLUGIN_PATH" >> ~/.bashrc
echo "export GZ_SIM_RESOURCE_PATH=\$HOME/ardupilot_gazebo/models:\$HOME/ardupilot_gazebo/worlds:\$GZ_SIM_RESOURCE_PATH" >> ~/.bashrc

echo ""
echo "=== INSTALL COMPLETE ==="
echo "Reboot recommended: sudo reboot"
