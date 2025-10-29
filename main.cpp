#include <iostream>
#include <iomanip>
#include <limits>
#include <math.h>

using namespace std;

#ifdef _WIN32
    #include <conio.h>
    #include <windows.h>
#else
    #include <termios.h>
    #include <unistd.h>
#endif

#define RESET "\033[0m"
#define RED "\033[31m"
#define GREY "\033[90m"
#define WHITE "\033[97m"
#define BOLD "\033[1m"

class View
{
public:
    static void clearInputBuffer()
    {
        cin.ignore(numeric_limits<streamsize>::max(), '\n');
    }

    static char getKey()
    {
#ifdef _WIN32
        return _getch();
#else
        termios oldt, newt;
        tcgetattr(STDIN_FILENO, &oldt);
        newt = oldt;
        newt.c_lflag &= ~(ICANON | ECHO);
        tcsetattr(STDIN_FILENO, TCSANOW, &newt);

        char ch = getchar();

        tcsetattr(STDIN_FILENO, TCSANOW, &oldt);
        return ch;
#endif
    }

    static void printWatchUsage()
    {
        std::cout << WHITE << BOLD << "IB-Noten Nutzung\n";
        std::cout << RESET << GREY << " › Drücken Sie " << WHITE << BOLD << "a" << RESET << GREY << " um die Umrechnungen für alle mögliche Punktzahlen zu berechnen.\n";
        std::cout << " › Drücken Sie " << WHITE << BOLD << "m" << RESET << GREY << " um die minimale IB-Punktzahl für eine bestimmte Durchnittsnote zu Berechnen.\n";
        std::cout << " › Drücken Sie " << WHITE << BOLD << "Eingabe" << RESET << GREY << " um die Durchschnittsnote für eine bestimmte Punktzahl zu berechnen.\n";
        std::cout << " › Drücken Sie " << WHITE << BOLD << "q" << RESET << GREY << " um die Anwendung zu beenden.\n"
                  << RESET;
    }
};

class CommandsRegistry
{
public:
    static void execute(const char key)
    {
        switch (key)
        {
        case 'a':
        case 'A':
            printMinGrade(24);
            break;
        case 'm':
        case 'M':
        {
            float desiredGrade;
            cout << GREY << "Gewünschte Durchnittsnote: " << RESET;
            cin >> desiredGrade;
            View::clearInputBuffer(); // Clear the input buffer

            int result = gradeToMinPoints(desiredGrade);

            if (result == 0)
                return;

            cout << GREY << "Für eine Durchschnittsnote " << WHITE << BOLD << desiredGrade
                 << RESET << GREY << " müssen Sie mindestens " << WHITE << BOLD << result
                 << RESET << GREY << " IB-Punkte erhalten\n"
                 << endl;
            break;
        }
        case '\n':
        case '\r':
        {
            int score;
            cout << GREY << "Ihre IB-Punktzahl: " << RESET;
            cin >> score;
            View::clearInputBuffer();

            float result = scoreToGrade(score);
            if (result == 0.0)
                return;

            cout << GREY << "Für " << WHITE << BOLD << score << RESET << GREY << " Punkte ist " << WHITE << BOLD << setprecision(2) << result << RESET << GREY << " die abitur-entsprechende Durchschnittsnote\n"
                 << endl;
            break;
        }
        default:
            // Ignore other keys
            break;
        }
    }

private:
    static float scoreToGrade(const int &P)
    {
        float Pmin = 24.0;
        float Pmax = 42.0;
        float N;

        if (P >= 42.0 && P <= 45.0)
        {
            N = 1.0;
        }
        else if (P >= Pmin && P < Pmax)
        {
            N = 1.0 + 3.0 * (Pmax - P) / (Pmax - Pmin);
        }
        else
        {
            cout << RED << "Ungültige Punktzahl, muss zwischen 24 und 45 liegen." << RESET << endl;
            return 0.0;
        }

        return N;
    }

    static int gradeToMinPoints(const float &N)
    {
        const float Pmin = 24.0;
        const float Pmax = 42.0;
        int P;

        if (N == 1.0)
        {
            return 42;
        }
        else if (N < 1.0 || N > 4.0)
        {
            cout << RED << "Ungültige Note, muss zwischen 1.0 und 4.0 liegen." << RESET << endl;
            return 0;
        }
        else
        {
            // N = 1 + 3 * (Pmax - P) / (Pmax - Pmin)
            // P berechnen:
            // N - 1 = 3 * (42 - P) / 18
            // (N - 1) * 18 = 3 * (42 - P)
            // (N - 1) * 6 = 42 - P
            // P = 42 - (N - 1) * 6

            P = static_cast<int>(round(Pmax - (N - 1.0) * (Pmax - Pmin) / 3.0));

            if (P < 24)
                P = 24;
            if (P > 41)
                P = 41;

            return P;
        }
    }

    static void printMinGrade(const int &minScore)
    {
        for (int i = minScore; i < 46; i++)
        {
            cout << GREY << "Für " << WHITE << BOLD << i << RESET << GREY << " Punkte ist " << WHITE << BOLD << setprecision(2) << scoreToGrade(i) << RESET << GREY << " die Abitur-Entsprechende Durchschnittsnote\n";
        }
        cout << endl;
    }
};

int main()
{
#ifdef _WIN32
    HANDLE hOut = GetStdHandle(STD_OUTPUT_HANDLE);
    DWORD dwMode = 0;
    GetConsoleMode(hOut, &dwMode);
    dwMode |= ENABLE_VIRTUAL_TERMINAL_PROCESSING;
    SetConsoleMode(hOut, dwMode);
#endif

    while (true)
    {
        View::printWatchUsage();
        char key = View::getKey();
        if (key == 'q' || key == 'Q')
        {
            std::cout << "\nAnwendung wird beendet...\n";
            break;
        }
        else
        {
            std::cout << "\n"
                      << std::endl;
            CommandsRegistry::execute(key);
        }
    }

    return 0;
}
