// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.
#include "pch.h"

#include "AdaptiveShowCardActionConfig.h"
#include "AdaptiveShowCardActionConfig.g.cpp"

namespace winrt::AdaptiveCards::Rendering::Uwp::implementation
{
    AdaptiveShowCardActionConfig::AdaptiveShowCardActionConfig(::AdaptiveCards::ShowCardActionConfig const& sharedShowCardActionConfig)
    {
        ActionMode = static_cast<winrt::AdaptiveCards::Rendering::Uwp::ActionMode>(sharedShowCardActionConfig.actionMode);
        Style = static_cast<winrt::ContainerStyle>(sharedShowCardActionConfig.style);
        InlineTopMargin = sharedShowCardActionConfig.inlineTopMargin;
    }
}
