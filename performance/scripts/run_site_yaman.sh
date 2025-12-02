#!/usr/bin/env bash
# set -euo pipefail: Garante que o script pare imediatamente em falhas (-e),
# variáveis indefinidas (-u), ou falhas em comandos dentro de pipes (-o pipefail).
set -euo pipefail

echo "Testando script bash"
# JMeter local no Windows:
# C:\Tools\apache-jmeter-5.6.3\bin\jmeter.bat

############################################
# 1) Descobre diretórios via pwd
############################################

# Pasta onde está ESTE script: .../gitflow-tutorial/performance/scripts
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Raiz do repo: sobe 2 níveis -> scripts -> performance -> gitflow-tutorial
BASE_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "Diretório do script : $SCRIPT_DIR"
echo "Diretório do projeto (raiz): $BASE_DIR"

############################################
# 2) Local do JMeter (GitHub x Windows)
############################################

# Caminho padrão usado no GitHub Actions (JMeter baixado em ./jmeter)
JMETER_HOME_DEFAULT="$BASE_DIR/jmeter"

# Caminho do seu JMeter local no Windows (via Git Bash)
# C:\Tools\apache-jmeter-5.6.3  =>  /c/Tools/apache-jmeter-5.6.3
JMETER_HOME_WINDOWS="/c/Tools/apache-jmeter-5.6.3"

# Se JMETER_HOME vier do ambiente, respeita ele
if [[ -n "${JMETER_HOME:-}" ]]; then
  JMETER_HOME_RESOLVED="$JMETER_HOME"
elif [[ -x "$JMETER_HOME_DEFAULT/bin/jmeter" ]]; then
  # Caso do GitHub Actions (Linux)
  JMETER_HOME_RESOLVED="$JMETER_HOME_DEFAULT"
elif [[ -f "$JMETER_HOME_WINDOWS/bin/jmeter.bat" ]]; then
  # Caso da sua máquina Windows (checa se o arquivo existe, não se é executável)
  JMETER_HOME_RESOLVED="$JMETER_HOME_WINDOWS"
else
  echo "ERRO: Não encontrei o JMeter."
  echo " - Ajuste o caminho em JMETER_HOME_WINDOWS dentro do script"
  echo "   ou exporte a variável JMETER_HOME antes de rodar."
  exit 1
fi

echo "JMETER_HOME usado: $JMETER_HOME_RESOLVED"

# Escolhe o executável correto
JMETER_BIN="$JMETER_HOME_RESOLVED/bin/jmeter"
# Se for caminho do Windows (/c/...), usa o .bat
if [[ "$JMETER_HOME_RESOLVED" == /c/* ]]; then
  JMETER_BIN="$JMETER_HOME_RESOLVED/bin/jmeter.bat"
fi

echo "Executável do JMeter: $JMETER_BIN"

############################################
# 3) Caminhos do teste e das saídas
############################################

# Caminho absoluto para o seu .jmx
TEST_PLAN="$BASE_DIR/performance/tests/site_yaman.jmx"

RESULTS_DIR="$BASE_DIR/performance/results"
REPORT_DIR="$BASE_DIR/performance/reports/site_yaman_html"
ARTIFACTS_DIR="$BASE_DIR/performance/artifacts"

# Garante que as pastas existem
mkdir -p "$RESULTS_DIR" "$REPORT_DIR" "$ARTIFACTS_DIR"

RESULTS_JTL="$RESULTS_DIR/site_yaman_results.jtl"
REPORT_ZIP="$ARTIFACTS_DIR/site_yaman_report.zip"

echo ">>> Limpando arquivos antigos..."
rm -f "$RESULTS_JTL" "$REPORT_ZIP"
rm -rf "$REPORT_DIR"/*

############################################
# 4) Executa o JMeter em modo não GUI
############################################
echo ">>> Executando JMeter em modo não GUI..."
"$JMETER_BIN" \
  -n \
  -t "$TEST_PLAN" \
  -l "$RESULTS_JTL" \
  -e \
  -o "$REPORT_DIR"

############################################
# 5) Gera ZIP do relatório HTML
############################################
echo ">>> Gerando ZIP do relatório HTML..."
(
  cd "$BASE_DIR"
  zip -r "$REPORT_ZIP" "performance/reports/site_yaman_html"
)

echo ">>> Terminado com sucesso!"
echo "Arquivo JTL  : $RESULTS_JTL"
echo "Relatório ZIP: $REPORT_ZIP"
