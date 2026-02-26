# ==============================================================================
#  PROJECT:  on iCESugar v1.5
# ==============================================================================

PROJ = ice_sugar
#PROJ = hardware_test_v

SRC_FOLDER = src


# Busca todos os .v em src recursivamente
#SRC = $(shell find $(SRC_FOLDER) -type f -name "*.v" ! -path "*/i2c/*" ! -name "*tb*" ! -name "*tf*")
SRC = $(shell find $(SRC_FOLDER) -type f -name "*.v"  ! -name "*tb*" ! -name "*tf*")

TESTBENCH = $(SRC_FOLDER)/$(PROJ)_tf.v
PCF       = $(SRC_FOLDER)/pins.pcf
DEVICE    = up5k
PACKAGE   = sg48

TARGET_FOLDER = target_folder

JSON      = $(TARGET_FOLDER)/$(PROJ).json
BIN       = $(TARGET_FOLDER)/$(PROJ).bin
ASC       = $(TARGET_FOLDER)/$(PROJ).asc
SVG       = $(TARGET_FOLDER)/$(PROJ).svg
VCD       = $(TARGET_FOLDER)/dump.vcd
SIM_OUT   = $(TARGET_FOLDER)/sim.out

# Configurações de Usuário e Caminhos
USER_NAME = $(USER)
DEST_PATH = /media/$(USER_NAME)/iCELink/
BROWSER   = google-chrome

# ==============================================================================
#  TARGETS
# ==============================================================================

# Default target
all: check syn prn bit prog

check:
	@mkdir -p $(TARGET_FOLDER)

# --- 1. SIMULATION (Waveform) ---
sim:
	iverilog -o $(SIM_OUT) $(SRC) $(TESTBENCH)
	vvp $(SIM_OUT)
	gtkwave $(VCD)

# --- 2. SYNTHESIS ---
# O comando agora é um só. Ele carrega $(SRC) (todos os arquivos) e sintetiza o topo.
syn: $(SRC)

	yosys -p "synth_ice40 -top $(PROJ) -json $(JSON)" $(SRC)


# --- 3. VIEW RTL SCHEMATIC ---
# Requer: npm install -g netlistsvg
rtl: $(SRC)
	# 1. Gera um JSON especial para visualização (com hierarquia preservada)
	yosys -p "prep -top $(PROJ); write_json $(JSON)" $(SRC)
	# 2. Converte JSON para SVG
	netlistsvg $(JSON) -o $(SVG)
	# 3. Abre no navegador
	$(BROWSER) $(SVG)

# --- 4. PLACE AND ROUTE ---
prn: $(JSON) $(PCF)
	nextpnr-ice40 --$(DEVICE) --package $(PACKAGE) --json $(JSON) --pcf $(PCF) --asc $(ASC)

# --- 5. BITSTREAM GENERATION ---
bit: $(ASC)
	icepack $(ASC) $(BIN)

# --- 6. PROGRAMMING ---
prog: bit
	@echo "Copiando para a placa iCESugar em $(DEST_PATH)..."
	@cp $(BIN) $(DEST_PATH) || echo "ERRO: Placa iCELink nao encontrada em $(DEST_PATH). Verifique a conexao USB."

# --- 7. CLEANUP ---
clean:
	rm -rf $(TARGET_FOLDER)

.PHONY: all sim syn rtl prn bit prog clean
