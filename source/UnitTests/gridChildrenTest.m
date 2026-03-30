function tests = gridChildrenTest
% Test suite for gridChildren layout utility.
% Run with: results = runtests('gridChildrenTest')
tests = functiontests(localfunctions);
end

%% Setup / teardown

function testCase = setupOnce(testCase)
    testCase.TestData.origDefaultFigureVisible = get(0, 'DefaultFigureVisible');
    % Hide figures during tests unless the user wants to inspect them
    keepFigs = evalin('base', 'exist(''GRIDCHILDREN_TEST_KEEP_FIGURES'',''var'') && GRIDCHILDREN_TEST_KEEP_FIGURES');
    if ~keepFigs
        set(0, 'DefaultFigureVisible', 'off');
    end
end

function teardownOnce(testCase)
    set(0, 'DefaultFigureVisible', testCase.TestData.origDefaultFigureVisible);
end

function teardown(~)
    % Set GRIDCHILDREN_TEST_KEEP_FIGURES=1 in the base workspace to
    % keep figures open after each test for visual inspection:
    %   GRIDCHILDREN_TEST_KEEP_FIGURES = 1; runtests('gridChildrenTest')
    keepFigs = evalin('base', 'exist(''GRIDCHILDREN_TEST_KEEP_FIGURES'',''var'') && GRIDCHILDREN_TEST_KEEP_FIGURES');
    if ~keepFigs
        close all;
    end
end

%% Basic layout with integer indices

function testBasicIntegerGrid(testCase)
    % Two buttons side by side, explicit widths
    f = figure('Position', [0 0 400 200], 'Units', 'pixels');
    btn1 = uicontrol(f, 'Style', 'pushbutton', 'String', 'A');
    btn2 = uicontrol(f, 'Style', 'pushbutton', 'String', 'B');

    gridChildren([1, 2], [btn1, btn2], ...
        'ColumnWidths', 100, 'RowHeights', 30, ...
        'ColumnMargins', 5, 'RowMargins', 5);

    % btn1 should be at x=5, btn2 at x=110
    verifyEqual(testCase, btn1.Position(1), 5, 'AbsTol', 1);
    verifyEqual(testCase, btn2.Position(1), 110, 'AbsTol', 1);
    % Both should have width=100, height=30
    verifyEqual(testCase, btn1.Position(3), 100, 'AbsTol', 1);
    verifyEqual(testCase, btn2.Position(3), 100, 'AbsTol', 1);
    verifyEqual(testCase, btn1.Position(4), 30, 'AbsTol', 1);
end

%% Basic layout with graphics object grid

function testBasicGraphicsGrid(testCase)
    % Same test but using a gobjects grid instead of indices
    f = figure('Position', [0 0 400 200], 'Units', 'pixels');
    btn1 = uicontrol(f, 'Style', 'pushbutton', 'String', 'A');
    btn2 = uicontrol(f, 'Style', 'pushbutton', 'String', 'B');

    gl = [btn1, btn2];
    gridChildren(gl, ...
        'ColumnWidths', 100, 'RowHeights', 30, ...
        'ColumnMargins', 5, 'RowMargins', 5);

    verifyEqual(testCase, btn1.Position(1), 5, 'AbsTol', 1);
    verifyEqual(testCase, btn2.Position(1), 110, 'AbsTol', 1);
end

%% Multiple rows (top-down ordering)

function testMultipleRows(testCase)
    % Row 1 of the grid matrix should appear at the TOP visually
    f = figure('Position', [0 0 300 200], 'Units', 'pixels');
    btnTop = uicontrol(f, 'Style', 'pushbutton', 'String', 'Top');
    btnBot = uicontrol(f, 'Style', 'pushbutton', 'String', 'Bottom');

    gl = [1; 2];  % Row 1 = btnTop, row 2 = btnBot
    gridChildren(gl, [btnTop, btnBot], ...
        'ColumnWidths', 100, 'RowHeights', 40, ...
        'RowMargins', 0, 'ColumnMargins', 0);

    % btnTop should be higher (larger Y) than btnBot
    verifyGreaterThan(testCase, btnTop.Position(2), btnBot.Position(2));
end

%% Column spanning

function testColumnSpan(testCase)
    % A button spanning two columns should be as wide as both columns
    f = figure('Position', [0 0 400 200], 'Units', 'pixels');
    btn1 = uicontrol(f, 'Style', 'pushbutton', 'String', 'Narrow');
    btn2 = uicontrol(f, 'Style', 'pushbutton', 'String', 'Narrow');
    btnWide = uicontrol(f, 'Style', 'pushbutton', 'String', 'Wide');

    gl = [1, 2; 3, 3];  % btnWide spans both columns in row 2
    gridChildren(gl, [btn1, btn2, btnWide], ...
        'ColumnWidths', 80, 'RowHeights', 30, ...
        'ColumnMargins', 5, 'RowMargins', 5);

    % btnWide should span from column 1 left edge to column 2 right edge
    expectedWidth = 80 + 5 + 80;  % col1 + margin + col2
    verifyEqual(testCase, btnWide.Position(3), expectedWidth, 'AbsTol', 1);
end

%% Row spanning

function testRowSpan(testCase)
    % A button spanning two rows should be as tall as both rows
    f = figure('Position', [0 0 400 200], 'Units', 'pixels');
    btnTall = uicontrol(f, 'Style', 'pushbutton', 'String', 'Tall');
    btnShort = uicontrol(f, 'Style', 'pushbutton', 'String', 'Short');

    gl = [1, 2; 1, 0];  % btnTall spans both rows in column 1
    gridChildren(gl, [btnTall, btnShort], ...
        'ColumnWidths', 80, 'RowHeights', 30, ...
        'ColumnMargins', 5, 'RowMargins', 5);

    expectedHeight = 30 + 5 + 30;  % row1 + margin + row2
    verifyEqual(testCase, btnTall.Position(4), expectedHeight, 'AbsTol', 1);
end

%% Empty cells (zeros)

function testEmptyCells(testCase)
    % Zeros in the grid leave cells empty — no error
    f = figure('Position', [0 0 400 200], 'Units', 'pixels');
    btn1 = uicontrol(f, 'Style', 'pushbutton', 'String', '1');
    btn2 = uicontrol(f, 'Style', 'pushbutton', 'String', '2');

    gl = [1, 0; 0, 2];  % Diagonal layout
    gridChildren(gl, [btn1, btn2], ...
        'ColumnWidths', 80, 'RowHeights', 30, ...
        'ColumnMargins', 5, 'RowMargins', 5);

    % btn1 top-left, btn2 bottom-right
    verifyGreaterThan(testCase, btn1.Position(2), btn2.Position(2));
    verifyLessThan(testCase, btn1.Position(1), btn2.Position(1));
end

%% Auto-sizing from child dimensions

function testAutoWidthFromChildren(testCase)
    % When ColumnWidths is NaN, columns should size to their widest child
    f = figure('Position', [0 0 400 200], 'Units', 'pixels');
    btnNarrow = uicontrol(f, 'Style', 'pushbutton', 'String', 'N', ...
        'Position', [0 0 40 25]);
    btnWide = uicontrol(f, 'Style', 'pushbutton', 'String', 'Wide button', ...
        'Position', [0 0 120 25]);

    gl = [1; 2];  % Both in same column
    gridChildren(gl, [btnNarrow, btnWide], ...
        'RowHeights', 30, 'ColumnMargins', 0, 'RowMargins', 0);

    % Column width determined by btnWide (120), btnNarrow should be
    % centered since it's narrower and column width wasn't explicit
    verifyEqual(testCase, btnNarrow.Position(3), 40, 'AbsTol', 1);
    verifyEqual(testCase, btnWide.Position(3), 120, 'AbsTol', 1);
end

function testAutoHeightFromChildren(testCase)
    % When RowHeights is NaN, rows should size to their tallest child
    f = figure('Position', [0 0 400 200], 'Units', 'pixels');
    btnShort = uicontrol(f, 'Style', 'pushbutton', 'String', 'S', ...
        'Position', [0 0 60 20]);
    btnTall = uicontrol(f, 'Style', 'pushbutton', 'String', 'T', ...
        'Position', [0 0 60 50]);

    gl = [1, 2];  % Both in same row
    gridChildren(gl, [btnShort, btnTall], ...
        'ColumnWidths', 60, 'ColumnMargins', 0, 'RowMargins', 0);

    % Row height determined by btnTall (50), btnShort should be centered
    verifyEqual(testCase, btnShort.Position(4), 20, 'AbsTol', 1);
    verifyEqual(testCase, btnTall.Position(4), 50, 'AbsTol', 1);
end

%% FitToWidth

function testFitToWidth(testCase)
    % Grid should scale to fill the entire parent width
    f = figure('Position', [0 0 400 200], 'Units', 'pixels');
    btn1 = uicontrol(f, 'Style', 'pushbutton', 'String', '1');
    btn2 = uicontrol(f, 'Style', 'pushbutton', 'String', '2');

    gl = [1, 2];
    gridChildren(gl, [btn1, btn2], ...
        'ColumnWidths', 50, 'RowHeights', 30, ...
        'ColumnMargins', 10, 'RowMargins', 5, ...
        'FitToWidth', true);

    % Right edge of btn2 + trailing margin should approximately equal
    % the parent width
    rightEdge = btn2.Position(1) + btn2.Position(3);
    % Allow some tolerance for scaling math
    verifyEqual(testCase, rightEdge, 400 - 10 * (400/130), 'AbsTol', 5);
end

%% FitToHeight

function testFitToHeight(testCase)
    % Grid should scale to fill the entire parent height
    f = figure('Position', [0 0 400 200], 'Units', 'pixels');
    btn1 = uicontrol(f, 'Style', 'pushbutton', 'String', '1');
    btn2 = uicontrol(f, 'Style', 'pushbutton', 'String', '2');

    gl = [1; 2];
    gridChildren(gl, [btn1, btn2], ...
        'ColumnWidths', 80, 'RowHeights', 30, ...
        'ColumnMargins', 5, 'RowMargins', 10, ...
        'FitToHeight', true);

    % Top edge of the top button + trailing margin should approximately
    % equal the parent height
    topEdge = btn1.Position(2) + btn1.Position(4);
    verifyLessThanOrEqual(testCase, topEdge, 200);
    verifyGreaterThan(testCase, topEdge, 150);  % Should use most of the height
end

%% Per-column margins

function testPerColumnMargins(testCase)
    % Different margins for each column
    f = figure('Position', [0 0 400 200], 'Units', 'pixels');
    btn1 = uicontrol(f, 'Style', 'pushbutton', 'String', '1');
    btn2 = uicontrol(f, 'Style', 'pushbutton', 'String', '2');

    gl = [1, 2];
    gridChildren(gl, [btn1, btn2], ...
        'ColumnWidths', 80, 'RowHeights', 30, ...
        'ColumnMargins', [10, 20, 10], ...  % left, between, right
        'RowMargins', 5);

    % btn1 at x=10, btn2 at x=10+80+20=110
    verifyEqual(testCase, btn1.Position(1), 10, 'AbsTol', 1);
    verifyEqual(testCase, btn2.Position(1), 110, 'AbsTol', 1);
end

%% Centering behavior for undersized children

function testCenteringInExplicitColumn(testCase)
    % A narrow child in an explicitly-wide column should be resized to fill
    f = figure('Position', [0 0 400 200], 'Units', 'pixels');
    btn = uicontrol(f, 'Style', 'pushbutton', 'String', 'X', ...
        'Position', [0 0 40 25]);

    gl = 1;
    gridChildren(gl, btn, ...
        'ColumnWidths', 200, 'RowHeights', 50, ...
        'ColumnMargins', 0, 'RowMargins', 0);

    % With explicit column width, child should be resized to fill
    verifyEqual(testCase, btn.Position(3), 200, 'AbsTol', 1);
    verifyEqual(testCase, btn.Position(4), 50, 'AbsTol', 1);
end

function testCenteringInAutoColumn(testCase)
    % In an auto-width column with two children of different widths,
    % the narrower one should be centered
    f = figure('Position', [0 0 400 200], 'Units', 'pixels');
    btnWide = uicontrol(f, 'Style', 'pushbutton', 'String', 'Wide', ...
        'Position', [0 0 120 25]);
    btnNarrow = uicontrol(f, 'Style', 'pushbutton', 'String', 'N', ...
        'Position', [0 0 40 25]);

    gl = [1; 2];
    gridChildren(gl, [btnWide, btnNarrow], ...
        'RowHeights', 30, 'ColumnMargins', 0, 'RowMargins', 0);

    % btnNarrow should be centered: x = (120-40)/2 = 40
    verifyEqual(testCase, btnNarrow.Position(1), 40, 'AbsTol', 1);
    % btnWide should be at x=0 (it defines the column width)
    verifyEqual(testCase, btnWide.Position(1), 0, 'AbsTol', 1);
end

%% Mixed control types

function testMixedControlTypes(testCase)
    % Verify it works with different uicontrol styles
    f = figure('Position', [0 0 400 300], 'Units', 'pixels');
    popup = uicontrol(f, 'Style', 'popupmenu', 'String', {'One', 'Two'});
    edit = uicontrol(f, 'Style', 'edit', 'String', 'text');
    check = uicontrol(f, 'Style', 'checkbox', 'String', 'Check me');
    btn = uicontrol(f, 'Style', 'pushbutton', 'String', 'Go');

    gl = [1, 2; 3, 4];
    gridChildren(gl, [popup, edit, check, btn], ...
        'ColumnWidths', 120, 'RowHeights', 25, ...
        'ColumnMargins', 5, 'RowMargins', 5);

    % All four controls should have the explicit dimensions
    for ctrl = [popup, edit, check, btn]
        verifyEqual(testCase, ctrl.Position(3), 120, 'AbsTol', 1);
        verifyEqual(testCase, ctrl.Position(4), 25, 'AbsTol', 1);
    end
end

%% Controls inside a uipanel

function testInsidePanel(testCase)
    % gridChildren should work with controls parented to a uipanel
    f = figure('Position', [0 0 400 300], 'Units', 'pixels');
    panel = uipanel(f, 'Units', 'pixels', 'Position', [10 10 200 100]);
    btn1 = uicontrol(panel, 'Style', 'pushbutton', 'String', '1');
    btn2 = uicontrol(panel, 'Style', 'pushbutton', 'String', '2');

    gl = [1, 2];
    gridChildren(gl, [btn1, btn2], ...
        'ColumnWidths', 80, 'RowHeights', 30, ...
        'ColumnMargins', 5, 'RowMargins', 5);

    % Positions should be relative to the panel, not the figure
    verifyEqual(testCase, btn1.Position(1), 5, 'AbsTol', 1);
    verifyEqual(testCase, btn2.Position(1), 90, 'AbsTol', 1);
end

%% Error cases

function testMismatchedParentsErrors(testCase)
    % Children with different parents should error
    f1 = figure('Position', [0 0 200 200]);
    f2 = figure('Position', [0 0 200 200]);
    btn1 = uicontrol(f1, 'Style', 'pushbutton', 'String', '1');
    btn2 = uicontrol(f2, 'Style', 'pushbutton', 'String', '2');

    verifyError(testCase, ...
        @() gridChildren([1, 2], [btn1, btn2], 'ColumnWidths', 80, 'RowHeights', 30), ...
        '');
end

function testInvalidRectangleErrors(testCase)
    % L-shaped layout should error (not a filled rectangle)
    f = figure('Position', [0 0 400 300]);
    btn1 = uicontrol(f, 'Style', 'pushbutton', 'String', '1');

    % Index 1 appears in an L-shape: (1,1), (2,1), (2,2) — not a rectangle
    gl = [1, 0; 1, 1];
    verifyError(testCase, ...
        @() gridChildren(gl, btn1, 'ColumnWidths', 80, 'RowHeights', 30), ...
        '');
end

function testOutOfRangeIndexErrors(testCase)
    % Index 5 with only 2 children should error
    f = figure('Position', [0 0 400 200]);
    btn1 = uicontrol(f, 'Style', 'pushbutton', 'String', '1');
    btn2 = uicontrol(f, 'Style', 'pushbutton', 'String', '2');

    gl = [1, 5];
    verifyError(testCase, ...
        @() gridChildren(gl, [btn1, btn2], 'ColumnWidths', 80, 'RowHeights', 30), ...
        '');
end
