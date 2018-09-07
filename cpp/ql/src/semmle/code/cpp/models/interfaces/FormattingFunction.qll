/**
 * Provides a class for modeling `printf`-style formatting functions. To use
 * this QL library, create a QL class extending `DataFlowFunction` with a
 * characteristic predicate that selects the function or set of functions you
 * are modeling. Within that class, override the predicates provided by
 * `FormattingFunction` to match the flow within that function.
 */

import semmle.code.cpp.Function
/**
 * A type that is used as a format string by any formatting function, or `wchar_t` if
 * there is none.
 */
private Type getAFormatterWideTypeOrDefault() {
  result = getAFormatterWideType().(PointerType).getBaseType() or
  (
    not exists(getAFormatterWideType().(PointerType).getBaseType()) and
    result instanceof Wchar_t
  )
}

/**
 * A standard library function that uses a `printf`-like formatting string.
 */
abstract class FormattingFunction extends Function {
  /** Gets the position at which the format parameter occurs. */
  abstract int getFormatParameterIndex();

  /**
   * Holds if the default meaning of `%s` is a `wchar_t *`, rather than
   * a `char *` (either way, `%S` will have the opposite meaning).
   */
  predicate isWideCharDefault() { none() }

  /**
   * Gets the default character type expected for `%s` by this function.  Typically
   * `char` or `wchar_t`.
   */
  Type getDefaultCharType() {
    result = getParameter(getFormatParameterIndex()).getType().
      getUnderlyingType().(PointerType).getBaseType().stripTopLevelSpecifiers()
  }

  /**
   * Gets the non-default character type expected for `%S` by this function.  Typically
   * `wchar_t` or `char`.  On some snapshots there may be multiple results where we can't tell
   * which is correct for a particular function.
   */
  Type getNonDefaultCharType() {
  	(
  	  getDefaultCharType().getSize() = 1 and
  	  result = getAFormatterWideTypeOrDefault()
  	) or (
  	  getDefaultCharType().getSize() > 1 and
  	  result instanceof PlainCharType
  	)
  }

  /**
   * Gets the wide character type for this function.  This is usually `wchar_t`.  On some
   * snapshots there may be multiple results where we can't tell which is correct for a
   * particular function.
   */
  Type getWideCharType() {
    (
      result = getDefaultCharType() or
      result = getNonDefaultCharType()
    ) and
    result.getSize() > 1
  }

  /**
   * Gets the position at which the output parameter, if any, occurs.
   */
  int getOutputParameterIndex() { none() }

  /**
   * Gets the position of the first format argument, corresponding with
   * the first format specifier in the format string.
   */
  int getFirstFormatArgumentIndex() { result = getNumberOfParameters() }

  /**
   * Gets the position of the buffer size argument, if any.
   */
  int getSizeParameterIndex() { none() }
}