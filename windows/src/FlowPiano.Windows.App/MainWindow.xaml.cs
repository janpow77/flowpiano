using System.Windows;
using System.Windows.Controls;
using FlowPiano.Windows.Core;

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

    private void OnKeySelectionChanged(object sender, SelectionChangedEventArgs e)
    {
        if (sender is ComboBox { SelectedItem: PitchClass key } && DataContext is MainWindowViewModel vm)
        {
            vm.SetKeyCommand.Execute(key);
        }
    }

    private void OnProgressionSelectionChanged(object sender, SelectionChangedEventArgs e)
    {
        if (sender is ComboBox { SelectedItem: ProgressionTemplate prog } && DataContext is MainWindowViewModel vm)
        {
            vm.SelectProgressionCommand.Execute(prog);
        }
    }
}
