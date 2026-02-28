import 'package:flutter/material.dart';

class CustomAutocompleteField extends StatelessWidget {
  final List<String> options;
  final String hintText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? initialValue;
  final ValueChanged<String>? onChanged;
  final bool readOnly;

  const CustomAutocompleteField({
    super.key,
    required this.options,
    required this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.initialValue,
    this.onChanged,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Autocomplete<String>(
          initialValue: TextEditingValue(text: initialValue ?? ''),
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (readOnly) {
              return const Iterable<String>.empty();
            }
            if (textEditingValue.text == '') {
              return options;
            }
            return options.where((String option) {
              return option.toLowerCase().contains(
                textEditingValue.text.toLowerCase(),
              );
            });
          },
          onSelected: (String selection) {
            if (onChanged != null && !readOnly) {
              onChanged!(selection);
            }
          },
          fieldViewBuilder:
              (
                BuildContext context,
                TextEditingController textEditingController,
                FocusNode focusNode,
                VoidCallback onFieldSubmitted,
              ) {
                return TextFormField(
                  controller: textEditingController,
                  focusNode: focusNode,
                  readOnly: readOnly,
                  onChanged: onChanged,
                  onFieldSubmitted: (String value) {
                    onFieldSubmitted();
                  },
                  style: TextStyle(
                    fontSize: 16,
                    color: readOnly
                        ? const Color(0xFF64748B)
                        : const Color(0xFF0F172A), // slate-900 / slate-500
                  ),
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: const TextStyle(
                      color: Color(0xFF94A3B8), // slate-400
                    ),
                    prefixIcon: prefixIcon,
                    suffixIcon: suffixIcon,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFFE2E8F0),
                      ), // slate-200
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF007FFF),
                        width: 2,
                      ),
                    ),
                  ),
                );
              },
          optionsViewBuilder:
              (
                BuildContext context,
                AutocompleteOnSelected<String> onSelected,
                Iterable<String> options,
              ) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4.0,
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: constraints.maxWidth,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8.0),
                        shrinkWrap: true,
                        itemCount: options.length,
                        itemBuilder: (BuildContext context, int index) {
                          final String option = options.elementAt(index);
                          return InkWell(
                            onTap: () {
                              onSelected(option);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12.0,
                                horizontal: 16.0,
                              ),
                              child: Text(option),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
        );
      },
    );
  }
}
