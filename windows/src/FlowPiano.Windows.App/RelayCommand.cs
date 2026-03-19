using System.Windows.Input;

namespace FlowPiano.Windows.App;

public sealed class RelayCommand(Action execute) : ICommand
{
    public bool CanExecute(object? parameter) => true;
    public void Execute(object? parameter) => execute();
    public event EventHandler? CanExecuteChanged;
}

public sealed class RelayCommand<T>(Action<T> execute) : ICommand
{
    public bool CanExecute(object? parameter) => true;
    public void Execute(object? parameter)
    {
        if (parameter is T typed)
            execute(typed);
    }
    public event EventHandler? CanExecuteChanged;
}
