//
//  ACRChoiceSetFullScreenView.mm
//  AdaptiveCards
//
//  Created by Jyoti Kukreja on 07/11/22.
//  Copyright © 2022 Microsoft. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ACRChoiceSetFullScreenView.h"
#import "ACRChoiceSetCompactStyleView.h"
#import "ACOBaseCardElementPrivate.h"
#import "ACOBundle.h"
#import "ACRActionDelegate.h"
#import "ACRBaseCardElementRenderer.h"
#import "ChoicesData.h"
#import "ACRInputLabelView.h"
#import "ACRView.h"
#import "ChoiceInput.h"
#import "ChoiceSetInput.h"
#import "HostConfig.h"
#import "UtiliOS.h"
#import "ACODebouncer.h"

@interface ACRChoiceSetFullScreenView() <MSFSearchBarDelegate,UITextFieldDelegate,ACODebouncerDelegate,UITableViewDelegate,UITableViewDataSource>
@end

typedef enum {
    none = 0,
    staticDataSource = 1,
    dynamicDataSource = 2
} TSChoicesDataSource;

@implementation ACRChoiceSetFullScreenView {
    UITextField *_textField;
    MSFSearchBar *_searchBar;
    ACOFilteredDataSource *_filteredDataSource;
    ACOBaseCardElement *_inputElem;
    dispatch_queue_t _global_queue;
    NSString *_inputLabel;
    UITableView *_listView;
    __weak ACRView *_rootView;
    ACODebouncer *_debouncer;
    ACRChoiceSetFullScreenView *_controller;
    NSInteger _wrapLines;
    TSChoicesDataSource _dataSourceType;
    ACOChoiceSetCompactStyleValidator *_validator;
    UIStackView *_container;
    ACRChoiceSetCompactStyleView *_delegate;
}

- (instancetype)initWithInputChoiceSet:(ACOBaseCardElement *)acoElem
                              rootView:(ACRView *)rootView
                            hostConfig:(ACOHostConfig *)acoConfig
                              delegate:(ACRChoiceSetCompactStyleView *)delegate
{
    self = [super init];
    if (self) {
        std::shared_ptr<BaseCardElement> elem = [acoElem element];
        std::shared_ptr<ChoiceSetInput> choiceSet = std::dynamic_pointer_cast<ChoiceSetInput>(elem);
        _rootView = rootView;
        _inputElem = acoElem;
        _delegate = delegate;
        // configure helper objects
        
        _filteredDataSource = [[ACOFilteredDataSource alloc] init];
        _validator = [[ACOChoiceSetCompactStyleValidator alloc] init:acoElem dataSource:_filteredDataSource];
        
        // configure debouncer
        _global_queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        _debouncer = [[ACODebouncer alloc] initWithDelay:0.2];
        _debouncer.delegate = self;

        // configure UI
        _listView = [[UITableView alloc] init];
        _listView.dataSource = self;
        _listView.delegate = self;
        _listView.accessibilityIdentifier = [NSString stringWithUTF8String:choiceSet->GetId().c_str()];
        _listView.backgroundColor = MSFColors.surfacePrimary;
        [_listView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
        // _listView.translatesAutoresizingMaskIntoConstraints = NO;
        [_listView registerClass:UITableViewCell.self forCellReuseIdentifier:@"SauceCell"];
        self.filteredListView = _listView;

        ACRBaseCardElementRenderer *renderer = [[ACRRegistration getInstance] getRenderer:[NSNumber numberWithInt:(int)choiceSet->GetElementType()]];
        if (renderer && [renderer respondsToSelector:@selector(configure:rootView:baseCardElement:hostConfig:)]) {
            // configure input UI
            [renderer configure:_container rootView:rootView baseCardElement:acoElem hostConfig:acoConfig];
        }
        
        _rootView = rootView;
        _wrapLines = choiceSet->GetWrap() ? 0 : 1;

        std::shared_ptr<ChoicesData> choicesData = choiceSet->GetChoicesData();
        
        _dataSourceType = none;
        if (choicesData->GetType().compare((AdaptiveCardSchemaKeyToString(AdaptiveCardSchemaKey::DataQuery))) == 0 )
        {
            _dataSourceType = dynamicDataSource;
        } else if (choiceSet->GetChoiceSetStyle() == ChoiceSetStyle::Filtered) {
            _dataSourceType =  staticDataSource;
        }
    }

    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = MSFColors.surfacePrimary;
    [self setupNavigationItemView];
    UIView *mainview = [[UIView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:mainview];
    [mainview setFrame:self.view.bounds];
    [mainview setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
    _container = [[UIStackView alloc] initWithFrame:CGRectZero];
    _container.axis = UILayoutConstraintAxisVertical;
    _container.layoutMargins = UIEdgeInsetsMake(16, 16, 16, 16);
    _container.layoutMarginsRelativeArrangement = YES;
    _container.spacing = 16;
    [mainview addSubview:_container];
    _container.translatesAutoresizingMaskIntoConstraints = NO;
    _listView.rowHeight = UITableViewAutomaticDimension;
    _searchBar = [self buildSearchbBarWithPlaceholder:@"Enter a search term"];
    
    [_container addArrangedSubview:_searchBar];
    UIView *separator0 = [[UIView alloc] init];
    separator0.backgroundColor = UIColor.grayColor;
    
    [separator0.heightAnchor constraintEqualToConstant:1].active = YES;
    
    [_container addArrangedSubview:separator0];
    
    [_container addArrangedSubview:_listView];
    
    [NSLayoutConstraint activateConstraints:@[
        [[_container topAnchor] constraintEqualToAnchor:[mainview topAnchor]],
        [[_container bottomAnchor] constraintEqualToAnchor:[mainview bottomAnchor]],
        [[_container leftAnchor] constraintEqualToAnchor:[mainview leftAnchor]],
        [[_container widthAnchor] constraintEqualToAnchor:[mainview widthAnchor]],
        [[_searchBar heightAnchor] constraintEqualToConstant:20],
    ]];
    [NSLayoutConstraint activateConstraints:@[
        [[_listView bottomAnchor] constraintEqualToAnchor:[mainview bottomAnchor]]
    ]];
    [_listView reloadData];
    [_searchBar becomeFirstResponder];
}


- (void)dealloc
{
    _debouncer.delegate = nil;
}

- (void)setupNavigationItemView {
    [self.navigationItem setTitle:@"typeahead search"];
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Back"
                                     style:UIBarButtonItemStylePlain
                                    target:self
                                    action:@selector(backButtonClicked)];
    self.navigationItem.leftBarButtonItem = backButton;
}

- (IBAction)backButtonClicked {
    [self dismiss];
}

-(void)dismiss {
    [self dismissViewControllerAnimated:NO completion:nil];
}

-(MSFSearchBar *) buildSearchbBarWithPlaceholder:(NSString *)placeholder {
    MSFSearchBar *searchBar = [[MSFSearchBar alloc] initWithFrame:CGRectZero];
    searchBar.delegate = self;
    searchBar.style = MSFSearchBarStyleDarkContent;
    searchBar.placeholderText = placeholder;
    searchBar.translatesAutoresizingMaskIntoConstraints = NO;
    searchBar.userInteractionEnabled = YES;
    return searchBar;
}

#pragma mark - MSFSearchBarDelegate Methods
- (void)searchBar:(MSFSearchBar * _Nonnull)searchBar didUpdateSearchText:(NSString * _Nullable)newSearchText {
    switch (_dataSourceType) {
        case staticDataSource:
            if ([newSearchText length]) {
                [_filteredDataSource updatefilteredListForStaticTypeahead:newSearchText];
            } else {
                [_filteredDataSource resetFilter];
            }
            [self updateListViewLayout];
            break;
        case dynamicDataSource:
            [_debouncer postInput:newSearchText];
            break;
        default:
            break;
    }
}

- (void)searchBarDidBeginEditing:(MSFSearchBar * _Nonnull)searchBar {
    
}

- (void)searchBarDidRequestSearch:(MSFSearchBar * _Nonnull)searchBar {
}

- (void)searchBarDidCancel:(MSFSearchBar * _Nonnull)searchBar {

}

#pragma mark - TSDebouncerDelegate Methods specifically for dynamic typeahead
- (void)debouncerDidSendOutput:(id)output
{
    if ([output isKindOfClass:NSString.class])
    {
        dispatch_async(_global_queue, ^{
            __weak typeof(self) weakSelf = self;
            [self->_rootView.acrActionDelegate onChoiceSetQueryChange:output acoElem:self->_inputElem completion:^(NSArray<NSString *> * _choices, NSError *error) {
                __strong typeof(self) strongSelf = weakSelf;
                if (!error) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if ([output length]) {
                            [strongSelf->_filteredDataSource updatefilteredListForDynamicTypeahead:_choices];
                        } else {
                            [strongSelf->_filteredDataSource resetFilter];
                        }
                        [strongSelf updateListViewLayout];
                    });
                }
            }];
        });
    }
}

#pragma mark - UITableViewDelegate Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _filteredDataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"filterred-cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] init];
    }
    cell.textLabel.text = [_filteredDataSource getItemAt:indexPath.row];
    cell.textLabel.numberOfLines = _wrapLines;
    cell.accessibilityLabel = [NSString stringWithFormat:@"%@, %@", _inputLabel, cell.textLabel.text];
    cell.accessibilityValue = [NSString stringWithFormat:@"%ld of %ld", indexPath.row + 1, [self tableView:tableView numberOfRowsInSection:0]];
    cell.accessibilityIdentifier = [NSString stringWithFormat:@"%@, %@", self.id, cell.textLabel.text];
    cell.accessibilityTraits = UIAccessibilityTraitButton;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    _searchBar.searchText = [_filteredDataSource getItemAt:indexPath.row];
    [_delegate updateSelectedChoiceInTextField:[_filteredDataSource getItemAt:indexPath.row]];
    [self dismiss];
    [self resignFirstResponder];
}

- (void) updateListViewLayout {
    [_listView reloadData];
}
@end


