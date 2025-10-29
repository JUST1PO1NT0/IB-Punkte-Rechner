# colours
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # RESET

# configs
APP_NAME="IB-Noten-Rechner"
SOURCE_FILE="main.cpp"
OUTPUT_DIR="dist"
BUILD_DIR="build"

# coloured output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

# Überprüfen ob das Befehl existiert
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

create_dirs() {
    mkdir -p $OUTPUT_DIR
    mkdir -p $BUILD_DIR
}

build_macos() {
    print_step "Building macOS Universal Binary"
    
    if command_exists clang++; then
        clang++ -arch x86_64 -arch arm64 -o $OUTPUT_DIR/$APP_NAME-mac $SOURCE_FILE -std=c++11
        if [ $? -eq 0 ]; then
            print_status "macOS Universal Binary created: $OUTPUT_DIR/$APP_NAME-mac"
            chmod +x $OUTPUT_DIR/$APP_NAME-mac
        else
            print_error "Failed to build macOS binary"
        fi
    else
        print_warning "clang++ not found, skipping macOS build"
    fi
}

build_windows() {
    print_step "Building Windows Executable"
    
    # cross-compiler check
    if command_exists x86_64-w64-mingw32-g++; then
        x86_64-w64-mingw32-g++ -o $OUTPUT_DIR/$APP_NAME.exe $SOURCE_FILE -std=c++11 -static -static-libgcc -static-libstdc++
        if [ $? -eq 0 ]; then
            print_status "Windows EXE created: $OUTPUT_DIR/$APP_NAME.exe"
        else
            print_error "Failed to build Windows executable"
        fi
    else
        print_warning "mingw-w64 not found, skipping Windows cross-compilation"
        echo "Install with: brew install mingw-w64"
    fi
}

build_linux() {
    print_step "Building Linux Binary"
    
    if command_exists g++; then
        # check if on linux or cross-compilation
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            g++ -o $OUTPUT_DIR/$APP_NAME-linux $SOURCE_FILE -std=c++11
            if [ $? -eq 0 ]; then
                print_status "Linux binary created: $OUTPUT_DIR/$APP_NAME-linux"
                chmod +x $OUTPUT_DIR/$APP_NAME-linux
            else
                print_error "Failed to build Linux binary"
            fi
        else
            print_warning "Not on Linux, creating Linux binary with local compiler (may not be fully compatible)"
            g++ -o $OUTPUT_DIR/$APP_NAME-linux $SOURCE_FILE -std=c++11
            chmod +x $OUTPUT_DIR/$APP_NAME-linux
        fi
    else
        print_warning "g++ not found, skipping Linux build"
    fi
}

# detect platform
launch_app() {
    print_step "Launching Application"
    
    case "$OSTYPE" in
        darwin*)
            if [ -f "$OUTPUT_DIR/$APP_NAME-mac" ]; then
                print_status "Running macOS version..."
                ./$OUTPUT_DIR/$APP_NAME-mac
            else
                print_error "macOS binary not found. Build it first with: ./build.sh build"
            fi
            ;;
        linux-gnu*)
            if [ -f "$OUTPUT_DIR/$APP_NAME-linux" ]; then
                print_status "Running Linux version..."
                ./$OUTPUT_DIR/$APP_NAME-linux
            else
                print_error "Linux binary not found. Build it first with: ./build.sh build"
            fi
            ;;
        msys*|cygwin*)
            if [ -f "$OUTPUT_DIR/$APP_NAME.exe" ]; then
                print_status "Running Windows version..."
                ./$OUTPUT_DIR/$APP_NAME.exe
            else
                print_error "Windows EXE not found. Build it first with: ./build.sh build"
            fi
            ;;
        *)
            print_warning "Unknown OS: $OSTYPE"
            if [ -f "$OUTPUT_DIR/$APP_NAME-mac" ]; then
                print_status "Trying macOS binary..."
                ./$OUTPUT_DIR/$APP_NAME-mac
            elif [ -f "$OUTPUT_DIR/$APP_NAME-linux" ]; then
                print_status "Trying Linux binary..."
                ./$OUTPUT_DIR/$APP_NAME-linux
            elif [ -f "$OUTPUT_DIR/$APP_NAME.exe" ]; then
                print_status "Trying Windows binary with Wine..."
                if command_exists wine; then
                    wine $OUTPUT_DIR/$APP_NAME.exe
                else
                    print_error "No compatible binary found and Wine not available"
                fi
            else
                print_error "No binaries found. Build first with: ./build.sh build"
            fi
            ;;
    esac
}

# Function to show build information
show_info() {
    print_step "Build Information"
    echo "Source file: $SOURCE_FILE"
    echo "Output directory: $OUTPUT_DIR/"
    echo "Available binaries:"
    ls -la $OUTPUT_DIR/ 2>/dev/null || echo "No binaries built yet"
    
    echo ""
    echo "Dependencies needed for cross-compilation:"
    echo "  macOS -> Windows: brew install mingw-w64"
    echo "  Testing Windows EXE on macOS: brew install wine"
}

# Function to clean build artifacts
clean_build() {
    print_step "Cleaning Build Artifacts"
    rm -rf $OUTPUT_DIR
    rm -rf $BUILD_DIR
    print_status "Build artifacts cleaned"
}

# Function to show usage
show_usage() {
    echo "IB Grade Converter Build Script"
    echo ""
    echo "Usage: ./build.sh [command]"
    echo ""
    echo "Commands:"
    echo "  build      Build all platform binaries (default)"
    echo "  macos      Build only macOS binary"
    echo "  windows    Build only Windows binary" 
    echo "  linux      Build only Linux binary"
    echo "  run        Build all and launch application"
    echo "  launch     Launch existing application (no build)"
    echo "  clean      Clean build artifacts"
    echo "  info       Show build information"
    echo "  help       Show this help message"
    echo ""
    echo "Examples:"
    echo "  ./build.sh           # Build all binaries"
    echo "  ./build.sh run       # Build all and launch"
    echo "  ./build.sh launch    # Launch without building"
}

# Main script logic
case "${1:-build}" in
    ("build")
        create_dirs
        build_macos
        build_windows
        build_linux
        show_info
        ;;
    ("macos")
        create_dirs
        build_macos
        ;;
    ("windows")
        create_dirs
        build_windows
        ;;
    ("linux")
        create_dirs
        build_linux
        ;;
    ("run")
        create_dirs
        build_macos
        build_windows
        build_linux
        launch_app;
        ;;
    ( "launch")
        launch_app
        ;;
    ("clean")
        clean_build
        ;;
    ("info")
        show_info
        ;;
    ("help"|"-h"|"--help")
        show_usage
        ;;
    (*)
        print_error "Unknown command: $1"
        echo ""
        show_usage
        exit 1
        ;;
esac