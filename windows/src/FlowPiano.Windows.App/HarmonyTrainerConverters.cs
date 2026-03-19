using System.Globalization;
using System.Windows.Data;
using System.Windows.Media;
using FlowPiano.Windows.Core;

namespace FlowPiano.Windows.App;

/// <summary>Hookpad-style color for scale degrees 1-7.</summary>
public sealed class DegreeToColorConverter : IValueConverter
{
    public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
    {
        var degree = value is int d ? d : 0;
        var hex = degree switch
        {
            1 => "#E84D3D",
            2 => "#D4B038",
            3 => "#A8D65C",
            4 => "#26AD61",
            5 => "#00BDD4",
            6 => "#3399DB",
            7 => "#9C59B5",
            _ => "#555555"
        };

        var opacity = parameter is string s && double.TryParse(s, CultureInfo.InvariantCulture, out var o) ? o : 1.0;
        var color = (Color)ColorConverter.ConvertFromString(hex);
        color.A = (byte)(255 * opacity);
        return new SolidColorBrush(color);
    }

    public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture) =>
        throw new NotSupportedException();
}

/// <summary>Green/yellow/red/gray for exercise result.</summary>
public sealed class ExerciseResultToColorConverter : IValueConverter
{
    public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
    {
        var result = value is ExerciseResult r ? r : ExerciseResult.Waiting;
        return result switch
        {
            ExerciseResult.Correct => new SolidColorBrush(Color.FromRgb(0x2E, 0xCC, 0x71)),
            ExerciseResult.Incorrect => new SolidColorBrush(Color.FromRgb(0xE7, 0x4C, 0x3C)),
            ExerciseResult.Partial => new SolidColorBrush(Color.FromRgb(0xF3, 0x9C, 0x12)),
            _ => new SolidColorBrush(Color.FromRgb(0x99, 0x99, 0x99))
        };
    }

    public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture) =>
        throw new NotSupportedException();
}

/// <summary>Converts Inversion enum to German label (1. Umk., 2. Umk., etc.).</summary>
public sealed class InversionToLabelConverter : IValueConverter
{
    public object Convert(object value, Type targetType, object parameter, CultureInfo culture) =>
        value is Inversion inv ? inv switch
        {
            Inversion.First => "1. Umk.",
            Inversion.Second => "2. Umk.",
            Inversion.Third => "3. Umk.",
            _ => ""
        } : "";

    public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture) =>
        throw new NotSupportedException();
}

/// <summary>Returns German name for PitchClass enum values.</summary>
public sealed class PitchClassToGermanNameConverter : IValueConverter
{
    public object Convert(object value, Type targetType, object parameter, CultureInfo culture) =>
        value is PitchClass pc ? pc.GetGermanName() : "";

    public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture) =>
        throw new NotSupportedException();
}

/// <summary>Converts DiatonicChord.Root to its german display (root + quality symbol).</summary>
public sealed class DiatonicChordDisplayConverter : IValueConverter
{
    public object Convert(object value, Type targetType, object parameter, CultureInfo culture) =>
        value is DiatonicChord dc ? dc.Root.GetGermanName() + dc.ChordType.Quality.GetSymbol() : "";

    public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture) =>
        throw new NotSupportedException();
}

/// <summary>Bool to Visibility (true=Visible, false=Collapsed). Pass parameter "invert" to invert.</summary>
public sealed class BoolToVisibilityConverter : IValueConverter
{
    public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
    {
        var b = value is true;
        if (parameter is "invert") b = !b;
        return b ? System.Windows.Visibility.Visible : System.Windows.Visibility.Collapsed;
    }

    public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture) =>
        throw new NotSupportedException();
}

/// <summary>Returns true if string is not null/empty (for Visibility binding).</summary>
public sealed class StringNotEmptyToVisibilityConverter : IValueConverter
{
    public object Convert(object value, Type targetType, object parameter, CultureInfo culture) =>
        value is string s && !string.IsNullOrEmpty(s) ? System.Windows.Visibility.Visible : System.Windows.Visibility.Collapsed;

    public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture) =>
        throw new NotSupportedException();
}
