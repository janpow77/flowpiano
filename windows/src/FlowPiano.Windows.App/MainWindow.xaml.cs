using System.Windows;

namespace FlowPiano.Windows.App;

public partial class MainWindow : Window
{
    public MainWindow()
    {
        InitializeComponent();
        var viewModel = new MainWindowViewModel();
        DataContext = viewModel;
        Closed += (_, _) => viewModel.Dispose();
    }
}
