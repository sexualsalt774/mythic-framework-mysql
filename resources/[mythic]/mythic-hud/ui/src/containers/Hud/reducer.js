export const initialState = {
    showing: process.env.NODE_ENV === 'production' ? false : true,
    config: {
        statusIcons: true,
        statusNumbers: false,
    },
};

export default (state = initialState, action) => {
    switch (action.type) {
        case 'SHOW_HUD':
            return {
                ...state,
                showing: true,
            };
        case 'HIDE_HUD':
            return {
                ...state,
                showing: false,
            };
        case 'TOGGLE_HUD':
            return {
                ...state,
                showing: !state.showing,
            };
        default:
            return state;
    }
};
